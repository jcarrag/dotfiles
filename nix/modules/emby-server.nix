{
  lib,
  pkgs,
  config,
  ...
}:

with lib;
with lib.types;
let
  cfg = config.programs.emby-server;
in
{
  options.programs.emby-server = {
    enable = mkEnableOption "Enable the Emby server service.";

    package = mkPackageOption pkgs "emby-server" { };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/emby-server";
      description = lib.mdDoc "The directory where Emby stores its data files.";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = true;
      description = lib.mdDoc "Open ports in the firewall for the Emby web interface.";
    };

    user = mkOption {
      default = "emby-server";
      type = types.str;
      description = lib.mdDoc ''
        User that runs Emby server.
      '';
    };
    group = mkOption {
      type = types.str;
      default = "emby-server";
      description = lib.mdDoc "Group account under which Emby server runs.";
    };
  };

  config = mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d '${cfg.dataDir}' 0700 ${cfg.user} ${cfg.group} - -"
    ];

    networking.firewall.interfaces.tailscale0 = mkIf cfg.openFirewall {
      allowedTCPPorts = [
        8096
        8920
      ];
      allowedUDPPorts = [
        1900
        7359
      ];
    };

    users.users = mkIf (cfg.user == "emby-server") ({
      emby-server = {
        isSystemUser = true;
        group = cfg.group;
        home = cfg.dataDir;
      };
    });

    users.groups = mkIf (cfg.group == "emby-server") { emby-server = { }; };

    systemd.services.emby-server = {
      description = "Emby server";
      after = [
        "network-online.target"
        "tailscaled.service"
      ];
      wants = [
        "network-online.target"
        "tailscaled.service"
      ];
      wantedBy = [ "multi-user.target" ];
      startLimitIntervalSec = 30;
      startLimitBurst = 2;
      environment = {
        EMBY_DATA = cfg.dataDir;
      };

      serviceConfig = {
        Type = "simple";
        ExecStartPre = pkgs.tailscaleWaitOnline;
        ExecStart = "${cfg.package}/bin/emby-server";
        Restart = "on-failure";
        User = cfg.user;
        Group = cfg.group;
      };
    };
  };

}
