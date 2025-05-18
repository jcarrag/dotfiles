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
    security.wrappers.sunshine = {
      owner = "root";
      group = "root";
      capabilities = "cap_sys_admin+p";
      source = "${pkgs.sunshine}/bin/sunshine";
    };
    systemd.user.services.sunshine = {
      description = "Sunshine self-hosted game stream host for Moonlight";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      startLimitBurst = 5;
      startLimitIntervalSec = 500;
      serviceConfig = {
        ExecStart = "${config.security.wrapperDir}/sunshine";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };
  };
}
