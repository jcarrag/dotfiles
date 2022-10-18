# XPS 13 9310 2-in-1
{ config, pkgs, ... }:

{
  # https://alexbakker.me/post/nixos-pci-passthrough-qemu-vfio.html
  # https://forum.level1techs.com/t/nixos-vfio-pcie-passthrough/130916
  # boot.kernelParams = [ "intel_iommu=on" ];

  boot.initrd.kernelModules = [ "amdgpu" ];

  services = {
    xserver = {
      xrandrHeads = [
        {
          output = "eDP-1";
          primary = true;
          monitorConfig = ''
            Option "PreferredMode" "1920x1200"
          '';
        }
      ];
      resolutions = [
        { x = 2560; y = 1600; }
        { x = 2048; y = 1280; }
        { x = 1920; y = 1200; }
        { x = 1280; y = 800; }
        { x = 1024; y = 640; }
      ];
    };
    udev = {
      # swap left alt with meta on magic keyboard
      extraHwdb = ''
        evdev:input:b0011v0001p0001*
          KEYBOARD_KEY_db=leftalt
          KEYBOARD_KEY_38=leftmeta
      '';
    };
  };

  users.extraGroups.vboxusers.members = [ "james" ];
}
