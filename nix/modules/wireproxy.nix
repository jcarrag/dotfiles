{
  config,
  pkgs,
  ...
}:

let
  # Mullvad's relay list (which mozwire relay save fetches to build the
  # WireGuard config) currently includes one relay with a null public_key
  # (bg-sof-wg-003 as of 2026-09), which mozwire 0.8.1's strict struct can't
  # deserialize - breaking `mozwire relay save` for every relay, not just
  # that one. Patched upstream at https://github.com/NilsIrl/MozWire; drop
  # this override once a release ships the fix.
  mozwire = pkgs.mozwire.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./patches/mozwire-null-pubkey.patch ];
  });

  mkWireproxy =
    # region: mozwire relay hostname prefix, e.g. "nl-ams", "us-nyc".
    # Mozilla periodically retires/renumbers individual relays within a
    # region, so we match on region only and take whichever one relay
    # mozwire returns first, rather than pinning an exact hostname.
    { region, port }:
    let
      mozillavpnDir = "/var/lib/wireproxy";
      stableConf = "${region}.conf";
      privkeyFile = "${mozillavpnDir}/${region}.privkey";
      refresh_conf = pkgs.writeShellScript "refresh_${region}_conf" ''
        set -euo pipefail
        scratch=$(mktemp -d)
        trap 'rm -rf "$scratch"' EXIT

        # Reuse one persistent WireGuard key across runs rather than letting
        # mozwire generate (and register) a fresh one every time. Mozilla
        # accounts cap out at 5 registered device pubkeys, and a fresh
        # keypair per retry burns through that limit within a few restarts
        # (as happened when this unit was given Restart=on-failure).
        if [ ! -s "${privkeyFile}" ]; then
          ${pkgs.wireguard-tools}/bin/wg genkey > "${privkeyFile}"
        fi

        # Per-region --name: mozwire defaults it to the hostname, and Mozilla
        # replaces an existing device when a new key is added under the same
        # name, so NL and US would silently evict each other's key.
        ${mozwire}/bin/mozwire relay save "^${region}-" \
          -o "$scratch" \
          -n 1 \
          --no-browser \
          --name "${config.networking.hostName}-${region}" \
          --privkey "$(cat "${privkeyFile}")" \
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
      # NetworkManager-wait-online is disabled (base-configuration.nix,
      # nixpkgs#180175), so network-online.target is reached without any
      # real connectivity check. At boot, ExecStartPre's DNS lookup to
      # vpn.mozilla.org can race WiFi association/DHCP and fail; retry
      # rather than staying dead until the next manual restart. Bounded via
      # StartLimit* so a persistent failure (e.g. account/API issue) can't
      # loop indefinitely - the persisted privkey above means these retries
      # no longer burn through Mozilla's 5-device cap either way.
      unitConfig = {
        StartLimitIntervalSec = "5m";
        StartLimitBurst = 5;
      };
      serviceConfig = {
        ExecStartPre = "${refresh_conf}";
        ExecStart = run_wireproxy;

        Restart = "on-failure";
        RestartSec = "5s";

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
