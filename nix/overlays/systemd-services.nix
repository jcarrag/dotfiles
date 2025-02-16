self: super:

with self.pkgs; {
  systemd-services = {
    services = {
      duck-dns = {
        description = "Update Duck DNS";
        serviceConfig = {
          Type = "exec";
          ExecStart = ''
            ${bashInteractive}/bin/bash -c '${curl}/bin/curl -k \"https://www.duckdns.org/update?domains=$$(${nettools}/bin/hostname)-0x00&token=$$(cat /home/james/secrets/duckdns/duck_dns_token)&ip=\"'
          '';
        };
      };
    };
    timers = {
      duck-dns = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "10s";
          OnUnitActiveSec = "5m";
          Unit = "duck-dns.service";
        };
      };
    };
    user.services = { };
  };
}
