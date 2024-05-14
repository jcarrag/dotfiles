# XPS 13 9320
{ pkgs, ... }:

{
  # https://alexbakker.me/post/nixos-pci-passthrough-qemu-vfio.html
  # https://forum.level1techs.com/t/nixos-vfio-pcie-passthrough/130916
  # boot.kernelParams = [ "intel_iommu=on" ];

  # AMD RX 5700 XT
  boot.initrd.kernelModules = [ "amdgpu" ];
  boot.initrd.luks.devices."luks-b6ee5065-b576-407b-9419-4651b91daad9".device = "/dev/disk/by-uuid/b6ee5065-b576-407b-9419-4651b91daad9";

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
  };

  services = {
    # the SDD is LUKS encrypted so a password is already required
    getty.autologinUser = "james";
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
  };

  users.extraGroups.vboxusers.members = [ "james" ];
}
