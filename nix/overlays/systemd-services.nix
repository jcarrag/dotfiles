self: super:

with self.pkgs; {
  # wait for tailscale to bind
  tailscaleWaitOnline = lib.mkBefore [
    "${pkgs.bash}/bin/bash -c 'until ${pkgs.iproute2}/bin/ip addr show dev tailscale0 | ${pkgs.gnugrep}/bin/grep -q -E \"inet 100(\.[0-9]{1,3}){3}\"; do sleep 5; done'"
  ];
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
    services =
      let
        mkWireproxy =
          # region: mozwire relay hostname prefix, e.g. "nl-ams", "us-nyc".
          # Mozilla periodically retires/renumbers individual relays within a
          # region, so we match on region only and take whichever one relay
          # mozwire returns first, rather than pinning an exact hostname.
          { region, port }:
          let
            mozillavpnDir = "/var/lib/wireproxy";
            stableConf = "${region}.conf";
            refresh_conf = pkgs.writeShellScript "refresh_${region}_conf" ''
              set -euo pipefail
              scratch=$(mktemp -d)
              trap 'rm -rf "$scratch"' EXIT
              ${self.pkgs.mozwire}/bin/mozwire relay save "^${region}-" \
                -o "$scratch" \
                -n 1 \
                --no-browser \
                --token "$(cat /run/agenix/mozwire_token)"
              picked=$(find "$scratch" -maxdepth 1 -name '*.conf' -print -quit)
              if [ -z "$picked" ]; then
                echo "refresh_${region}_conf: no relay matched ^${region}-, leaving existing config in place" >&2
                exit 1
              fi
              mv -f "$picked" "${mozillavpnDir}/${stableConf}"
            '';
            run_wireproxy = pkgs.writeShellScript "run_wireproxy" ''
              ${self.pkgs.wireproxy}/bin/wireproxy --silent --config <(cat <<-EOF
              WGConfig = ${mozillavpnDir}/${stableConf}
              [Socks5]
              BindAddress = 127.0.0.1:${port}
              EOF
              )
            '';
          in
          {
            description = "Wireproxy ${region} SOCKS server service";
            after = [ "network-online.target" ];
            wantedBy = [ "network-online.target" ];
            wants = [ "network-online.target" ];
            serviceConfig = {
              ExecStartPre = "${refresh_conf}";
              ExecStart = run_wireproxy;

              # Neither mozwire nor wireproxy need root: wireproxy tunnels
              # WireGuard entirely in userspace (no kernel wg interface, no
              # CAP_NET_ADMIN needed) and mozwire only needs to read its
              # token secret and write mozillavpnDir - both owned by this
              # dedicated static user (see nix/modules/secrets.nix).
              User = "wireproxy";
              Group = "wireproxy";
              StateDirectory = "wireproxy";
              StateDirectoryMode = "0750";

              # Hardening: deny everything by default. StateDirectory above
              # already carves out the one write hole needed (mozillavpnDir).
              ProtectSystem = "strict";
              ProtectHome = "read-only";
              NoNewPrivileges = true;
              PrivateTmp = true;
              PrivateDevices = true;
              ProtectKernelTunables = true;
              ProtectKernelModules = true;
              ProtectControlGroups = true;
              RestrictSUIDSGID = true;
              LockPersonality = true;
              RestrictRealtime = true;
              MemoryDenyWriteExecute = true;
              CapabilityBoundingSet = "";
              AmbientCapabilities = "";
            };
          };
      in
      {
        harmonia.serviceConfig.ExecStartPre = pkgs.tailscaleWaitOnline;
        harmonia.after = pkgs.tailscaleAfter;
        harmonia.wantedBy = pkgs.tailscaleWantedBy;
        harmonia.requires = pkgs.tailscaleRequires;
        # The hardened service's RestrictAddressFamilies is breaking the tailscale lookup (via AF_NETLINK)
        # https://github.com/NixOS/nixpkgs/blob/nixos-25.05/nixos/modules/services/networking/harmonia.nix#L112
        harmonia.serviceConfig.RestrictAddressFamilies = lib.mkForce "AF_UNIX AF_INET AF_INET6 AF_NETLINK";
        harmonia.serviceConfig.PrivateNetwork = lib.mkForce false;
        harmonia.serviceConfig.IPAddressDeny = lib.mkForce "";

        syncthing.serviceConfig.ExecStartPre = self.pkgs.tailscaleWaitOnline;
        syncthing.after = pkgs.tailscaleAfter;
        syncthing.wantedBy = pkgs.tailscaleWantedBy;
        syncthing.requires = pkgs.tailscaleRequires;

        wireproxyNL = mkWireproxy {
          region = "nl-ams";
          port = "1080";
        };
        wireproxyUS = mkWireproxy {
          region = "us-nyc";
          port = "1081";
        };
      };
    sockets = {
      harmonia.socketConfig.FreeBind = true;
    };
    timers = {
    };
    user = {
    };
  };
}
