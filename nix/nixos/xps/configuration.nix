# XPS 13 9320
{ pkgs, ... }:

{
  imports = [
    ../../modules/taffybar-my.nix
  ];

  # https://alexbakker.me/post/nixos-pci-passthrough-qemu-vfio.html
  # https://forum.level1techs.com/t/nixos-vfio-pcie-passthrough/130916
  # boot.kernelParams = [ "intel_iommu=on" ];

  # AMD RX 5700 XT
  boot.initrd.kernelModules = [ "amdgpu" ];

  programs.taffybar-my.enable = true;

  services = {
    tailscale = {
      enable = true;
      package = pkgs.unstable.tailscale;
    };
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
      extraHwdb = ''
        # internal keyboard
        evdev:input:b0011v0001p0001*
          KEYBOARD_KEY_db=leftalt
          KEYBOARD_KEY_38=leftmeta

        # [US office] Cherry USB keyboard
        evdev:input:b0003v046ApB090*
          KEYBOARD_KEY_700e3=leftalt
          KEYBOARD_KEY_700e2=leftmeta
      '';
    };
  };

  users.extraGroups.vboxusers.members = [ "james" ];
}
