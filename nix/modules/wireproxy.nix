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
      # One key (and so one Mozilla device slot) shared by every region on
      # this host. Accounts cap out at 5 devices, and Mozilla replaces an
      # existing device when a new key is added under the same name, so
      # per-region keys registered under the hostname evicted each other.
      privkeyFile = "${mozillavpnDir}/privkey";
      refresh_conf = pkgs.writeShellScript "refresh_${region}_conf" ''
        set -euo pipefail
        scratch=$(mktemp -d)
        trap 'rm -rf "$scratch"' EXIT

        # All regions start together at boot; serialise key generation and
        # registration so they don't each create or upload a key.
        exec 9>"${mozillavpnDir}/mozwire.lock"
        ${pkgs.util-linux}/bin/flock 9

        if [ ! -s "${privkeyFile}" ]; then
          ${pkgs.wireguard-tools}/bin/wg genkey > "${privkeyFile}"
        fi

        ${mozwire}/bin/mozwire relay save "^${region}-" \
          -o "$scratch" \
          -n 1 \
          --no-browser \
          --name "${config.networking.hostName}" \
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
      # real connectivity check and at boot mozwire's HTTPS call in
      # ExecStartPre races WiFi association/DHCP/DNS. There is no way to
      # take the network out of that call (mozwire always fetches
      # /vpn/account first, even with a cached token), so instead tolerate
      # its failure: the "-" prefix lets ExecStart run anyway, on the
      # ${stableConf} cached from the last successful refresh. That conf
      # stays valid across boots (persistent privkey; mozwire never
      # re-uploads a pubkey already in the device list) and its Endpoint is
      # a bare IP, so wireproxy starts offline and handshakes once the
      # network is up. If there is no cached conf yet, wireproxy fails on
      # the missing file and Restart below retries with backoff rather than
      # hitting a start limit. Retries are free w.r.t. Mozilla's 5-device
      # cap for the same reason.
      unitConfig = {
        StartLimitIntervalSec = 0;
      };
      serviceConfig = {
        ExecStartPre = "-${refresh_conf}";
        ExecStart = run_wireproxy;

        Restart = "on-failure";
        RestartSec = "5s";
        RestartSteps = 6;
        RestartMaxDelaySec = "5m";

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
