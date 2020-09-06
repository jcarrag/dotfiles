{ config, pkgs, unstable, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ../base-configuration.nix
    ];
  _module.args.unstable = unstable;

  boot.extraModprobeConfig = ''
    options snd_hda_intel enable=0,1
  '';

  services.xserver = {
    xrandrHeads = [
      { output = "eDP-1";
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
}
