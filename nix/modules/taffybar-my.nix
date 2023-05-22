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
        after = [ "display-manager.target" ];
        wantedBy = [ "display-manager.target" ];
        startLimitIntervalSec = 30;
        startLimitBurst = 2;

        serviceConfig = {
          ExecStart = "${pkgs.taffybar-my}/bin/taffybar-my";
          Restart = "on-failure";
        };
      };
    }
  );
}
