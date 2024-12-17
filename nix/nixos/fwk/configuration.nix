# Framework 13 7040
{ pkgs, ... }:

{
  # https://alexbakker.me/post/nixos-pci-passthrough-qemu-vfio.html
  # https://forum.level1techs.com/t/nixos-vfio-pcie-passthrough/130916
  # boot.kernelParams = [ "intel_iommu=on" ];

  # AMD RX 5700 XT
  boot.initrd.kernelModules = [ "amdgpu" ];

  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [
    5000 # harmonia
  ];

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
