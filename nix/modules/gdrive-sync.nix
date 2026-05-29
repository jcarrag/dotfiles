{ pkgs, ... }:

{
  # run `rclone config` to initialise API key
  # Choose: n (new remote) → name it "gdrive" → type "drive" → follow OAuth prompts
  # https://rclone.org/drive/#making-your-own-client-id
  environment.systemPackages = [ pkgs.rclone ];

  systemd.user.services.gdrive-sync = {
    description = "Google Drive bidirectional sync via rclone bisync";
    serviceConfig = {
      Type = "oneshot";
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
            --conflict-resolve newer \
            --conflict-loser num \
            --create-empty-src-dirs \
            --verbose
        else
          ${pkgs.rclone}/bin/rclone bisync "$LOCAL" "$REMOTE" \
            --conflict-resolve newer \
            --conflict-loser num \
            --create-empty-src-dirs \
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
