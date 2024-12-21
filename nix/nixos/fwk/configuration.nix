# Framework 13 7040
{ pkgs, ... }:

{
  # https://alexbakker.me/post/nixos-pci-passthrough-qemu-vfio.html
  # https://forum.level1techs.com/t/nixos-vfio-pcie-passthrough/130916
  boot.kernelParams = [ "intel_iommu=on" ];

  # AMD RX 5700 XT
  boot.initrd.kernelModules = [ "amdgpu" ];

  networking = {
    firewall = {
      allowedUDPPorts = [
        51820 # wireguard
      ];
      interfaces.tailscale0.allowedTCPPorts = [
        5000 # harmonia
      ];
    };
    wireguard = {
      enable = true;
      interfaces.wg0 = {
        ips = [ "10.69.69.2" ];
        listenPort = 51820;
        privateKeyFile = "/home/james/secrets/wireguard/fwk_private";
        peers = [
          {
            endpoint = "hm90-0x00.duckdns.org:51820";
            publicKey = "r6orhHvNkutxVJBGyLaFmcz5rllURDLiIs8nO6kIfRE=";
            allowedIPs = [ "10.69.69.1/32" ];
            persistentKeepalive = 25;
            dynamicEndpointRefreshSeconds = 25;
          }
          {
            # linode
            endpoint = "172.236.1.158:51820";
            publicKey = "QvAir8j5oU0vKr5xaotNPAY7wqH/6+7iEFxperJgiUA=";
            allowedIPs = [ "10.69.69.3/32" ];
            persistentKeepalive = 25;
            dynamicEndpointRefreshSeconds = 25;
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
