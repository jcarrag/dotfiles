# Framework 13 7040
{
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ../../modules/immich-camera-sync.nix
    ../../modules/gdrive-sync.nix
    ../../modules/hyprland-notifier.nix
    ../../modules/egpu-session.nix
    ../../modules/sunshine.nix
    ../../modules/tailscale-drive.nix
  ];

  # PCI bus rescan on eGPU hotplug; see the module for why it is needed.
  services.egpu-session = {
    enable = true;
    # Adds a "Hyprland (eGPU primary)" option at the login screen for demanding
    # games: direct scanout from the eGPU, no frame copy back to the iGPU. Pick
    # the plain "Hyprland" session when you might want to unplug.
    primarySession.enable = true;
  };

  # https://alexbakker.me/post/nixos-pci-passthrough-qemu-vfio.html
  # https://forum.level1techs.com/t/nixos-vfio-pcie-passthrough/130916
  # boot.initrd.kernelModules = [ "amdgpu" ];
  boot.kernelParams = [
    "intel_iommu=on"
    "pcie_aspm=off"
    # https://bbs.archlinux.org/viewtopic.php?id=302499
    # https://community.frame.work/t/fw13-amd-ui-freeze/64555/11
    "amdgpu.dcdebugmask=0x10"

    # these two break iGPU
    # "pcie_ports=native"
    # NOTE: no `assign-busses,hpbussize=0x33` here. Renumbering the buses to
    # reserve room for the eGPU moved the iGPU c1:00.0 -> 69:00.0, where its ROM
    # BAR can't be assigned ("bogus alignment") -> amdgpu can't find the video
    # BIOS -> probe fails with -22 -> Hyprland aborts in CBackend::create() with
    # no DRM device, so login drops straight back to the greeter.
    # Keep the MMIO reservations, which are what the eGPU actually needs.
    # "pci=assign-busses,hpbussize=0x33,realloc,hpmmiosize=128M,hpmmioprefsize=16G"

    # gemini says this will work for both igpu and egpu
    "pci=realloc,hpmmiosize=128M,hpmmioprefsize=2G"
  ];
  # Pin the compositor's *primary* GPU to the iGPU. The eGPU is still registered
  # as a secondary on hotplug, so its DisplayPort output lights up and games can
  # render on it via DRI_PRIME=pci-0000_07_00_0.
  #
  # Chosen for hot-unplug safety: losing a secondary GPU is far more survivable
  # than losing the one the desktop is composited on.
  #
  # The cost is frame copies over Thunderbolt, visible in the Hyprland log as
  # repeated "EGL (blit)" lines. Because compositing happens on the primary:
  #
  #   game on an eGPU output  (DP-13):  render eGPU -> blit to iGPU to
  #                                     composite -> blit back to eGPU to
  #                                     scan out                    [2 hops]
  #   game on an iGPU output  (eDP-1,
  #           DP-10 via dock):          render eGPU -> blit to iGPU  [1 hop]
  #
  # So games are counter-intuitively *faster* on the laptop panel or the dock's
  # HDMI than on the monitor wired straight to the eGPU. Setting this to
  # "/dev/dri/amd-rx9070xt:/dev/dri/amd-igpu" makes the eGPU primary and gives
  # eGPU outputs direct scanout with no blit, at the cost of the session very
  # likely dying on unplug.
  #
  # The previous value listed amd-5700xt and nuc-intel-igpu, which do not exist
  # on fwk and logged "Explicit device not found" on every boot.
  environment.sessionVariables.AQ_DRM_DEVICES = "/dev/dri/amd-igpu";

  networking.firewall.interfaces.tailscale0 = {
    allowedUDPPorts = [
      22000 # syncthing
      21027 # syncthing
    ];
    allowedTCPPorts = [
      8080 # metro
      8081 # metro
      9001 # metro
      9002 # metro
      5555 # harmonia
      8384 # syncthing
      22000 # syncthing
    ];
  };

  programs.bash.hyprland-notifier.enable = true;

  services = {
    harmonia.cache = {
      enable = true;
      # nix-store --generate-binary-cache-key fwk.tail7f031.ts.net harmonia.pem harmonia.pub
      signKeyPaths = [ "/home/james/secrets/harmonia.pem" ];
      settings = {
        bind = "100.124.115.79:5555";
      };
    };
    _sunshine = {
      enable = true;
      bindAddress = "100.124.115.79";
      adapterName = "/dev/dri/amd-igpu";
    };
    syncthing = {
      enable = true;
      group = "users";
      user = "james";
      dataDir = "/home/james/syncthing";
      guiAddress = "100.124.115.79:8384"; # fwk.tail7f031.ts.net
      settings = {
        devices = {
          hm90 = {
            id = "IEYHIZK-64FMYVQ-BUFCRXV-H5HXUE3-GI6LX52-6MKQTWA-TKBG4CD-DEBK5AY";
            autoAcceptFolders = true;
          };
          fwk = {
            id = "YJUN6RQ-M6J4OLM-AHX5T5E-R3EQZL2-63Y7SYJ-234K2G2-LZEXEON-6HDYUAX";
            autoAcceptFolders = true;
          };
          lunar-fwk = {
            id = "LE2NRU6-MD4PBOO-VEOTVRO-6GUGP53-2C2LL3L-WHU6MFN-2L3657P-MZHN2Q4";
            autoAcceptFolders = true;
          };
          ios12 = {
            id = "QVK42FI-XKHXEV3-5OZXZXG-RX6Z2N7-4ATD6DW-UVKPYRO-ICLP2PR-PBEUXAY";
            autoAcceptFolders = true;
          };
        };
        folders = {
          "notes" = {
            path = "/home/james/notes";
            maxConflicts = 0;
            devices = [
              "ios12"
              "hm90"
              "lunar-fwk"
            ];
          };
          "storyteller" = {
            path = "/home/james/storyteller";
            type = "receiveonly";
            versioning = {
              type = "simple";
              cleanupIntervalS = 60;
              params = {
                keep = "1";
                cleanoutDays = "30";
              };
            };
            devices = [
              "hm90"
            ];
          };
          "arr_backup" = {
            path = "/home/james/arr_backup";
            type = "receiveonly";
            versioning = {
              type = "simple";
              cleanupIntervalS = 60;
              params = {
                keep = "1";
                cleanoutDays = "30";
              };
            };
            devices = [
              "hm90"
            ];
          };
        };
      };
    };
    tailscale = {
      enable = true;
      package = pkgs.unstable.tailscale;
      extraSetFlags = [ "--accept-routes" ];
    };
  };

  systemd = lib.attrsets.recursiveUpdate pkgs.systemd-services {
  };

  virtualisation.docker.enable = true;
}
