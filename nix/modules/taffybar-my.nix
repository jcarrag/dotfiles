{ lib, pkgs, config, ... }:

with lib; with lib.types;
let
  cfg = config.programs.taffybar-my;
in
{
  options.programs.taffybar-my = {
    enable = mkEnableOption "Enable the taffybar service.";
  };

  config = mkIf cfg.enable (
    {
      environment.systemPackages = [
        pkgs.taffybar-my
      ];

      systemd.user.services.taffybar-my = {
        description = "Taffybar(-my)";
        after = [ "graphical-session.target" ];
        wantedBy = [ "graphical-session.target" ];
        restartTriggers = [ pkgs.taffybar-my ];
        # disable restart rate limiting until haskell mmap bug fixed
        # startLimitIntervalSec = 30;
        # startLimitBurst = 2;

        serviceConfig = {
          ExecStart = "${pkgs.taffybar-my}/bin/taffybar-my";
          Restart = "always";
          RestartSec = 1;
        };
      };
    }
  );
}
