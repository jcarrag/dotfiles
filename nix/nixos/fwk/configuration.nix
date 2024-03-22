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
    udev = {
      extraHwdb = ''
        # internal keyboard
        evdev:input:b0011v0001p0001*
          KEYBOARD_KEY_db=leftalt
          KEYBOARD_KEY_38=leftmeta
      '';
    };
    xserver.videoDrivers = [ "amdgpu" ];
  };
}
