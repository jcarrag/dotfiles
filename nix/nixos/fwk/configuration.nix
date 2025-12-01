# Framework 13 7040
{
  pkgs,
  config,
  lib,
  ...
}:

{
  imports = [
    ../../modules/sunshine.nix
  ];

  # https://alexbakker.me/post/nixos-pci-passthrough-qemu-vfio.html
  # https://forum.level1techs.com/t/nixos-vfio-pcie-passthrough/130916
  boot.kernelParams = [ "intel_iommu=on" ];

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

  programs.sunshine.enable = true;

  services = {
    greetd.settings.default_session.command = "${pkgs.tuigreet}/bin/tuigreet --asterisks --remember --remember-user-session --time --cmd ${config.programs.hyprland.package}/bin/Hyprland";
    harmonia = {
      enable = true;
      # nix-store --generate-binary-cache-key fwk.tail7f031.ts.net harmonia.pem harmonia.pub
      signKeyPaths = [ "/home/james/secrets/harmonia.pem" ];
      settings = {
        bind = "100.124.115.79:5555";
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
          ios12 = {
            id = "QVK42FI-XKHXEV3-5OZXZXG-RX6Z2N7-4ATD6DW-UVKPYRO-ICLP2PR-PBEUXAY";
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

  systemd = lib.attrsets.recursiveUpdate pkgs.systemd-services {
  };

  virtualisation.docker.enable = true;
}
