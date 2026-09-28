# NUC9i7QNX
{
  lib,
  config,
  pkgs,
  ...
}:

{
  imports = [
  ];

  boot.kernelParams = [
    "pci=realloc"
  ];

  services = {
    greetd = {
      enable = true;
      settings = {
        initial_session = {
          command = "${lib.getExe config.programs.uwsm.package} start -F -D Hyprland -- ${config.programs.hyprland.package}/bin/start-hyprland";
          user = "james";
        };
        default_session = {
          command = "${pkgs.tuigreet}/bin/tuigreet --remember --asterisks --cmd 'uwsm start -F -D Hyprland -- start-hyprland'";
        };
      };
    };
    tailscale = {
      enable = true;
      package = pkgs.unstable.tailscale;
      extraSetFlags = [ "--accept-routes" ];
    };
  };
}
