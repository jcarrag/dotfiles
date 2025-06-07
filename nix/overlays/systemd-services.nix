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
      # delay syncthing starting until tailscale binds
      syncthing.serviceConfig.ExecStartPre = lib.mkForce [
        "${pkgs.bash}/bin/bash -c 'until ${pkgs.iproute2}/bin/ip addr show dev tailscale0 | ${pkgs.gnugrep}/bin/grep -q -E \"inet 100(\.[0-9]{1,3}){3}\"; do sleep 1; done'"
      ];
      syncthing.after = lib.mkForce [
        "network-online.target"
        "tailscaled.service"
      ];
      syncthing.wants = lib.mkForce [
        "network-online.target"
        "tailscaled.service"
      ];
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
