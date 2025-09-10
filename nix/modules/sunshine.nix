# https://github.com/LongerHV/nixos-configuration/blob/b193c67526b8e02bb6e3078432b663c8c292d336/modules/nixos/sunshine.nix
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.sunshine;
in
{
  options.programs.sunshine = with lib; {
    enable = mkEnableOption "sunshine";
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.interfaces.tailscale0 = {
      allowedTCPPortRanges = [
        {
          from = 47984;
          to = 48010;
        }
      ];
      allowedUDPPortRanges = [
        {
          from = 47998;
          to = 48010;
        }
      ];
    };
    systemd.services.sunshine = {
      description = "Sunshine self-hosted game stream host for Moonlight";
      wantedBy = [
        "network-online.target"
      ];
      after = [
        "tailscaled.service"
      ];
      startLimitBurst = 5;
      startLimitIntervalSec = 500;
      serviceConfig = {
        ExecStartPre = pkgs.tailscaleWaitOnline;
        ExecStart = "${pkgs.sunshine}/bin/sunshine";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };
  };
}
