# Framework 13 7040
{ pkgs, ... }:

{
  # https://alexbakker.me/post/nixos-pci-passthrough-qemu-vfio.html
  # https://forum.level1techs.com/t/nixos-vfio-pcie-passthrough/130916
  # boot.kernelParams = [ "intel_iommu=on" ];

  # AMD RX 5700 XT
  boot.initrd.kernelModules = [ "amdgpu" ];

  networking = {
    firewall = {
      allowedUDPPorts = [
        51820 # wireguard
      ];
      interfaces."tailscale0".allowedTCPPorts = [
        5000 # harmonia
      ];
    };
    wireguard = {
      enable = true;
      interfaces.wg0 = {
        ips = [ "10.13.13.2" ];
        listenPort = 51820;
        privateKeyFile = "/home/james/secrets/wireguard/fwk_private";
        peers = [
          {
            # hades - downloaded config
            endpoint = "45.86.221.100:24762";
            publicKey = "aG/hA+lURm/3OjOBJU7S2FSvyZ9z1VjuBer6fasWOyM=";
            presharedKeyFile = "/home/james/secrets/wireguard/hades_fwk_presharedkey";
            allowedIPs = [ "10.13.13.1/32" ];
            persistentKeepalive = 25;
          }
        ];
      };
    };
  };

  services = {
    harmonia = {
      enable = false;
      # nix-store --generate-binary-cache-key fwk.tail7f031.ts.net harmonia.pem harmonia.pub
      signKeyPath = /home/james/secrets/harmonia.pem;
      settings = {
        bind = "100.124.115.79:5000";
      };
    };
    tailscale = {
      enable = true;
      package = pkgs.unstable.tailscale;
    };
    xserver.videoDrivers = [ "amdgpu" ];
  };

  systemd = pkgs.systemd-services;

  virtualisation.docker.enable = true;
}
