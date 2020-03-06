{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ../base-configuration.nix
    ];

  boot.extraModprobeConfig = ''
    options snd_hda_intel enable=0,1
  '';

  services.xserver = {
    xrandrHeads = [
      { output = "eDP-1";
        primary = true;
        monitorConfig = ''
          Option "PreferredMode" "2048x1280"
        '';
      }
    ];
    resolutions = [
      { x = 2560; y = 1600; }
      { x = 2048; y = 1280; }
      { x = 1280; y = 800; }
      { x = 1024; y = 640; }
    ];
  };
}
