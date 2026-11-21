self: super:

with self.pkgs; {
  tailscaleAfter = lib.mkAfter [
    "tailscaled.service"
  ];
  tailscaleRequires = lib.mkAfter [
    "tailscaled.service"
  ];
  tailscaleWantedBy = lib.mkAfter [
    "network-online.target"
  ];
  systemd-services = {
    services = {
      harmonia.after = pkgs.tailscaleAfter;
      harmonia.wantedBy = pkgs.tailscaleWantedBy;
      harmonia.requires = pkgs.tailscaleRequires;
      # The hardened service's RestrictAddressFamilies is breaking the tailscale lookup (via AF_NETLINK)
      # https://github.com/NixOS/nixpkgs/blob/nixos-25.05/nixos/modules/services/networking/harmonia.nix#L112
      harmonia.serviceConfig.RestrictAddressFamilies = lib.mkForce "AF_UNIX AF_INET AF_INET6 AF_NETLINK";
      harmonia.serviceConfig.PrivateNetwork = lib.mkForce false;
      harmonia.serviceConfig.IPAddressDeny = lib.mkForce "";

      syncthing.after = pkgs.tailscaleAfter;
      syncthing.wantedBy = pkgs.tailscaleWantedBy;
      syncthing.requires = pkgs.tailscaleRequires;

      # syncthing-init curls the GUI on the tailscale 100.x address. Until
      # tailscaled has assigned that address the kernel routes it out the
      # default route (ip_nonlocal_bind only helps the listener), so offline
      # the curl can never succeed. Keep the oneshot out of multi-user.target so
      # it cannot hold up graphical.target/login, and retry it in the background
      # until it succeeds, like harmonia/sunshine.
      syncthing-init.wantedBy = lib.mkForce [ "syncthing.service" ];
      syncthing-init.serviceConfig.TimeoutStartSec = 60;
      syncthing-init.serviceConfig.Restart = "on-failure";
      syncthing-init.serviceConfig.RestartSec = 30;
      syncthing-init.unitConfig.StartLimitIntervalSec = 0;
    };
    sockets = {
      harmonia.socketConfig.FreeBind = true;
    };
    timers = { };
    user = { };
  };
}
