{ lib, pkgs, config, ... }:

with lib; with lib.types;
let
  cfg = config.programs.emby-server;

  dataDir = "/var/lib/emby-server";
in
{
  options.programs.emby-server = {
    enable = mkEnableOption "Enable the Emby server service.";

    package = mkPackageOptionMD pkgs "emby-server" { };

    user = mkOption {
      default = "emby-server";
      type = types.str;
      description = lib.mdDoc ''
        User that runs Emby server.
      '';
    };
    group = mkOption {
      type = types.str;
      default = "users";
      description = lib.mdDoc "Group account under which Emby server runs.";
    };
  };

  config = mkIf cfg.enable (
    {
      environment.systemPackages = [
        cfg.package
      ];

      networking = {
        firewall = {
          allowedTCPPorts = [
            8096
            8920
          ];
          allowedUDPPorts = [
            1900
            7359
          ];
        };
      };

      users.users = optionalAttrs (cfg.user == "emby-server") ({
        emby-server = {
          group = cfg.group;
          isSystemUser = true;
          description = "Emby server user.";
          home = dataDir;
          createHome = true;
        };
      });

      users.groups = optionalAttrs (cfg.group == "emby-server") ({
        emby-server = { };
      });

      systemd.services.emby-server = {
        description = "Emby server";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        startLimitIntervalSec = 30;
        startLimitBurst = 2;

        serviceConfig = {
          ExecStart = "${cfg.package}/bin/emby-server";
          ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
          Restart = "on-failure";
          User = cfg.user;
          Group = cfg.group;
        };
      };
    }
  );
}
