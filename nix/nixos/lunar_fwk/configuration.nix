# Framework 13 7040
{
  pkgs,
  lib,
  config,
  ...
}:

let
  pam_fde_boot_pw = pkgs.callPackage ../../modules/pam-fde-boot-pw.nix { };
in
{
  imports = [
    ../../modules/immich-camera-sync.nix
    ../../modules/gdrive-sync.nix
    ../../modules/hyprland-notifier.nix
    ../../modules/sunshine.nix
    ../../modules/tailscale-drive.nix
    ../../modules/wireproxy.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Needed so the LUKS passphrase entered at boot is cached in the kernel
  # keyring (as key "cryptsetup"), which pam_fde_boot_pw then reads on
  # session open to auto-unlock gnome-keyring below.
  boot.initrd.systemd.enable = true;

  boot.initrd.luks.devices."luks-12b3e52f-f52d-4d93-bf9b-45aa1aa8260c".device =
    "/dev/disk/by-uuid/12b3e52f-f52d-4d93-bf9b-45aa1aa8260c";

  # Autologin straight into Hyprland (via UWSM) using greetd, and reuse the
  # LUKS passphrase (typed once at boot) to unlock the login keyring too.
  # Login password must match the LUKS passphrase for the keyring unlock
  # to succeed. Replaces lightdm's autoLogin, which had no mechanism to
  # feed a password to pam_gnome_keyring.
  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        command = "${lib.getExe config.programs.uwsm.package} start -F -D Hyprland -- ${config.programs.hyprland.package}/bin/start-hyprland";
        user = "james";
      };
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --remember --asterisks --cmd 'uwsm start -F -D Hyprland -- start-hyprland'";
      };
    };
  };

  security.pam.services.greetd.rules.session.fde_boot_pw = {
    control = "optional";
    modulePath = "${pam_fde_boot_pw}/lib/security/pam_fde_boot_pw.so";
    args = [ "inject_for=gkr" ];
    # Must run before gnome_keyring's own session rule so the password it
    # stashes is available for gnome_keyring to consume.
    order = config.security.pam.services.greetd.rules.session.gnome_keyring.order - 10;
  };

  # https://alexbakker.me/post/nixos-pci-passthrough-qemu-vfio.html
  # https://forum.level1techs.com/t/nixos-vfio-pcie-passthrough/130916
  # boot.kernelParams = [ "intel_iommu=on" ];

  # AMD RX 5700 XT
  boot.initrd.kernelModules = [ "amdgpu" ];
  boot.kernelParams = [
    # https://bbs.archlinux.org/viewtopic.php?id=302499
    # https://community.frame.work/t/fw13-amd-ui-freeze/64555/11
    "amdgpu.dcdebugmask=0x10"
  ];

  networking = {
    firewall = {
      allowedUDPPorts = [
      ];
      interfaces.tailscale0.allowedTCPPorts = [
        5555 # harmonia
      ];
    };
  };

  programs.bash.hyprland-notifier.enable = true;

  services = {
    harmonia.cache = {
      enable = true;
      # nix-store --generate-binary-cache-key fwk.tail7f031.ts.net harmonia.pem harmonia.pub
      signKeyPaths = [ "/home/james/secrets/harmonia.pem" ];
      settings = {
        bind = "100.102.227.124:5555";
      };
    };
    _sunshine = {
      enable = true;
      bindAddress = "100.102.227.124";
      adapterName = "/dev/dri/amd-igpu";
    };
    syncthing = {
      enable = true;
      group = "users";
      user = "james";
      dataDir = "/home/james/syncthing";
      guiAddress = "100.102.227.124:8384"; # lunar-fwk.tail7f031.ts.net
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
              "fwk"
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
    xserver.videoDrivers = [ "amdgpu" ];
  };

  systemd = lib.attrsets.recursiveUpdate pkgs.systemd-services {
  };

  virtualisation.docker.enable = true;
}
