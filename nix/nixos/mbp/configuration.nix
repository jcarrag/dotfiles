# MacBook Pro (Retina, 13-inch, Mid 2014)
{ config, pkgs, ... }:

{
  imports = [
    ../../modules/taffybar-my.nix
  ];

  hardware = {
    facetimehd.enable = true;
  };

  programs.taffybar-my.enable = true;

  services.xserver = {
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
}
