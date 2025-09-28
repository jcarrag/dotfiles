# NUC9i7QNX
{ lib, pkgs, ... }:

{
  imports = [
    ../../modules/sunshine.nix
  ];

  services = {
    tailscale = {
      enable = true;
      package = pkgs.unstable.tailscale;
      extraSetFlags = [ "--accept-routes" ];
    };
  };

  programs.sunshine.enable = true;
  # this won't work bc i'm not using service.sunshine
  # services.sunshine.settings = {
  #   adapter_name = "/dev/dri/renderWUT";
  #   sunshine_name = "nuc";
  # };

  # systemd.user.services.steam = {
  #   enable = true;
  #   description = "Open steam-gamescope at boot";
  #   serviceConfig = {
  #     ExecStart = "steam-gamescope"; # doens't exist in pkgs
  #     wantedBy = [ "graphical-session.target" ];
  #     Restart = "on-failure";
  #     RestartSec = "5s";
  #   };
  # };

  # services.greetd.settings.initial_session.command = lib.mkForce "steam-gamescope";
}
