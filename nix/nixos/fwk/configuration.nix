# Framework 13 7040
{ pkgs, ... }:

{
  # AMD iGPU
  boot.initrd.kernelModules = [ "amdgpu" ];

  services = {
    tailscale = {
      enable = true;
      package = pkgs.unstable.tailscale;
    };
    xserver.videoDrivers = [ "amdgpu" ];
  };
}
