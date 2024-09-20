self: super:

with self.pkgs;
{
  systemd-services = {
    user = {
      discord = {
        description = "Start Discord at launch";
        wantedBy = [ "graphical-session.target" ];
        serviceConfig.ExecStart = "${pkgs.unstable.discord}/bin/discord --start-minimized";
      };
    };
  };
}
