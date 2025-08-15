# Framework 13 7040
{
  pkgs,
  lib,
  config,
  ...
}:

{
  imports = [
    ../../modules/sunshine.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.luks.devices."luks-12b3e52f-f52d-4d93-bf9b-45aa1aa8260c".device =
    "/dev/disk/by-uuid/12b3e52f-f52d-4d93-bf9b-45aa1aa8260c";

  # https://alexbakker.me/post/nixos-pci-passthrough-qemu-vfio.html
  # https://forum.level1techs.com/t/nixos-vfio-pcie-passthrough/130916
  # boot.kernelParams = [ "intel_iommu=on" ];

  # AMD RX 5700 XT
  boot.initrd.kernelModules = [ "amdgpu" ];

  networking = {
    firewall = {
      allowedUDPPorts = [
      ];
      interfaces.tailscale0.allowedTCPPorts =
        if config.services.harmonia.enable then
          [
            5001 # harmonia
          ]
        else
          [ ];
    };
  };

  programs.sunshine.enable = true;

  services = {
    # the SDD is LUKS encrypted so a password is already required
    getty.autologinUser = "james";
    displayManager.autoLogin.user = "james";
    harmonia = {
      enable = true;
      # nix-store --generate-binary-cache-key fwk.tail7f031.ts.net harmonia.pem harmonia.pub
      signKeyPaths = [ "/home/james/secrets/harmonia.pem" ];
      settings = {
        bind = "100.102.227.124:5001";
      };
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

  systemd = pkgs.systemd-services // {
    services.harmonia.serviceConfig.ExecStartPre = lib.mkForce [
      "${pkgs.bash}/bin/bash -c 'until ${pkgs.iproute2}/bin/ip addr show dev tailscale0 | ${pkgs.gnugrep}/bin/grep -q -E \"inet 100(\.[0-9]{1,3}){3}\"; do sleep 1; done'"
    ];
    services.harmonia.after = lib.mkForce [
      "network-online.target"
      "tailscaled.service"
    ];
    services.harmonia.wants = lib.mkForce [
      "network-online.target"
      "tailscaled.service"
    ];
  };

  virtualisation.docker.enable = true;
}
