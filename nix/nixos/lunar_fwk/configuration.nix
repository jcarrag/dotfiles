# Framework 13 7040
{ pkgs, config, ... }:

{
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.luks.devices."luks-12b3e52f-f52d-4d93-bf9b-45aa1aa8260c".device = "/dev/disk/by-uuid/12b3e52f-f52d-4d93-bf9b-45aa1aa8260c";

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
            5000 # harmonia
          ]
        else
          [ ];
    };
  };

  services = {
    # the SDD is LUKS encrypted so a password is already required
    getty.autologinUser = "james";
    displayManager.autoLogin.user = "james";
    harmonia = {
      enable = false;
      # nix-store --generate-binary-cache-key fwk.tail7f031.ts.net harmonia.pem harmonia.pub
      signKeyPath = /home/james/secrets/harmonia.pem;
      settings = {
        bind = "100.124.115.79:5000";
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

  systemd = pkgs.systemd-services;

  virtualisation.docker.enable = true;

  #system.stateVersion = "24.05";
}
