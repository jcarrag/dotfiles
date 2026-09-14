{
  pkgs,
  ...
}:

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
        ${pkgs.mozwire}/bin/mozwire relay save "^${region}-" \
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
        ${pkgs.wireproxy}/bin/wireproxy --silent --config <(cat <<-EOF
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
        # CAP_NET_ADMIN needed) and mozwire only needs to read its token
        # secret and write mozillavpnDir - both owned by this dedicated
        # static user.
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
  # Dedicated static service account for wireproxyNL/wireproxyUS so they run
  # as neither james nor root, own the mozwire_token secret directly, and
  # own their own state dir (via StateDirectory in the unit, chowned to this
  # stable uid/gid).
  users.groups.wireproxy = { };
  users.users.wireproxy = {
    isSystemUser = true;
    group = "wireproxy";
  };

  age.secrets.mozwire_token = {
    file = ../secrets/mozwire_token.age;
    owner = "wireproxy";
    mode = "0400";
  };

  systemd.services.wireproxyNL = mkWireproxy {
    region = "nl-ams";
    port = "1080";
  };
  systemd.services.wireproxyUS = mkWireproxy {
    region = "us-nyc";
    port = "1081";
  };
}
