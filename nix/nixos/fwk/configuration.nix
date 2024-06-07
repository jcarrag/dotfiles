# Framework 13 7040
{ pkgs, ... }:

{
  # https://alexbakker.me/post/nixos-pci-passthrough-qemu-vfio.html
  # https://forum.level1techs.com/t/nixos-vfio-pcie-passthrough/130916
  # boot.kernelParams = [ "intel_iommu=on" ];

  # AMD RX 5700 XT
  boot.initrd.kernelModules = [ "amdgpu" ];

  services = {
    tailscale = {
      enable = true;
      package = pkgs.unstable.tailscale;
    };
    xserver.videoDrivers = [ "amdgpu" ];
  };
}
