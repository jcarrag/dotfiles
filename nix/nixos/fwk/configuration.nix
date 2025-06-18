# Framework 13 7040
{
  pkgs,
  ...
}:

{
  imports = [
    ../../modules/sunshine.nix
  ];

  # https://alexbakker.me/post/nixos-pci-passthrough-qemu-vfio.html
  # https://forum.level1techs.com/t/nixos-vfio-pcie-passthrough/130916
  boot.kernelParams = [ "intel_iommu=on" ];

  nix.gc.automatic = true;

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
      5001 # harmonia
      8384 # syncthing
      22000 # syncthing
    ];
  };

  programs.sunshine.enable = true;

  services = {
    getty.autologinUser = "james";
    displayManager.autoLogin.user = "james";
    harmonia = {
      enable = true;
      # nix-store --generate-binary-cache-key fwk.tail7f031.ts.net harmonia.pem harmonia.pub
      signKeyPaths = [ "/home/james/secrets/harmonia.pem" ];
      settings = {
        bind = "100.124.115.79:5001";
      };
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
        };
      };
    };
    tailscale = {
      enable = true;
      package = pkgs.unstable.tailscale;
      extraSetFlags = [ "--accept-routes" ];
    };
  };

  systemd = pkgs.systemd-services;

  virtualisation.docker.enable = true;
}
