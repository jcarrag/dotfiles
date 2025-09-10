self: super:

with self.pkgs; {
  tailscaleWaitOnline = lib.mkForce [
    "${pkgs.bash}/bin/bash -c 'until ${pkgs.iproute2}/bin/ip addr show dev tailscale0 | ${pkgs.gnugrep}/bin/grep -q -E \"inet 100(\.[0-9]{1,3}){3}\"; do sleep 1; done'"
  ];
  tailscaleAfter = lib.mkForce [
    "network-online.target"
    "tailscaled.service"
  ];
  tailscaleWants = lib.mkForce [
    "network-online.target"
    "tailscaled.service"
  ];
  systemd-services = {
    services = {
      # wait for tailscale for bind
      harmonia.serviceConfig.ExecStartPre = pkgs.tailscaleWaitOnline;
      # The hardened service's RestrictAddressFamilies is breaking the tailscale lookup (via AF_NETLINK)
      # https://github.com/NixOS/nixpkgs/blob/nixos-25.05/nixos/modules/services/networking/harmonia.nix#L112
      harmonia.serviceConfig.RestrictAddressFamilies = lib.mkForce "AF_UNIX AF_INET AF_INET6 AF_NETLINK";
      # delay syncthing starting until tailscale binds
      harmonia.after = pkgs.tailscaleAfter;
      harmonia.wants = pkgs.tailscaleWants;

      syncthing.serviceConfig.ExecStartPre = self.pkgs.tailscaleWaitOnline;
      syncthing.after = pkgs.tailscaleAfter;
      syncthing.wants = pkgs.tailscaleWants;
    };
    timers = {
    };
    user.services = {
      gammastep = {
        description = "Display colour temperature adjustment";
        partOf = [ "graphical-session.target" ];
        after = [ "graphical-session.target" ];
        wantedBy = [ "graphical-session.target" ];
        serviceConfig = {
          ExecStart = "${gammastep}/bin/gammastep -v";
          Restart = "on-failure";
        };
      };
      gammastep-indicator = {
        description = "Indicator for display colour temperature adjustment";
        after = [ "gammastep.service" ];
        wantedBy = [ "gammastep.service" ];
        serviceConfig = {
          ExecStart = "${gammastep}/bin/gammastep-indicator";
          Restart = "on-failure";
        };
      };
    };
  };
}
