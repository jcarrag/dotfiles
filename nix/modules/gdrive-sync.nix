{ pkgs, config, ... }:

{
  # The rclone config (with the "gdrive" remote and its OAuth token) comes from
  # the rclone_conf agenix secret, so no per-host `rclone config` is needed.
  # To (re)generate it, on a machine with a browser run `rclone config`:
  # n (new remote) → name it "gdrive" → type "drive" → follow OAuth prompts,
  # then `agenix -e rclone_conf.age` and paste ~/.config/rclone/rclone.conf.
  # https://rclone.org/drive/#making-your-own-client-id
  # The OAuth client must be published ("In production"), otherwise Google
  # expires the refresh token after 7 days.
  environment.systemPackages = [ pkgs.rclone ];

  systemd.user.services.gdrive-sync = {
    description = "Google Drive bidirectional sync via rclone bisync";
    serviceConfig = {
      Type = "oneshot";
      # rclone rewrites its config when it refreshes the access token and the
      # agenix file is read-only, so work from a per-run copy in $XDG_RUNTIME_DIR.
      RuntimeDirectory = "gdrive-sync";
      Environment = "RCLONE_CONFIG=%t/gdrive-sync/rclone.conf";
      ExecStartPre = "${pkgs.coreutils}/bin/install -m600 ${config.age.secrets.rclone_conf.path} %t/gdrive-sync/rclone.conf";
      ExecStart = pkgs.writeShellScript "gdrive-sync" ''
        set -euo pipefail

        LOCAL="/home/james/gdrive"
        REMOTE="gdrive:"
        BISYNC_PATH="${pkgs.rclone}/bin/rclone bisync"

        mkdir -p "$LOCAL"

        # On first run the bisync state files won't exist — use --resync to initialise
        STATE_DIR="$HOME/.cache/rclone/bisync"
        if [ ! -d "$STATE_DIR" ] || [ -z "$(ls -A "$STATE_DIR" 2>/dev/null)" ]; then
          echo "No bisync state found, running initial --resync"
          ${pkgs.rclone}/bin/rclone bisync "$LOCAL" "$REMOTE" \
            --resync \
            --resync-mode newer \
            --conflict-resolve newer \
            --conflict-loser num \
            --create-empty-src-dirs \
            --verbose
        else
          ${pkgs.rclone}/bin/rclone bisync "$LOCAL" "$REMOTE" \
            --conflict-resolve newer \
            --conflict-loser num \
            --create-empty-src-dirs \
            --resilient \
            --recover \
            --verbose
        fi
      '';
    };
    # Only run when network is available
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
  };

  systemd.user.timers.gdrive-sync = {
    description = "Run Google Drive sync hourly";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5min"; # first run 5 mins after login
      OnUnitActiveSec = "1h";
      Persistent = true; # catch up on missed runs (e.g. after suspend)
      RandomizedDelaySec = "2min"; # avoid thundering-herd on the hour
    };
  };
}
