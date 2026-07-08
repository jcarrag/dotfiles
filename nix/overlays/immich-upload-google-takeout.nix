self: super:

{
  immich-upload-google-takeout = super.pkgs.writeShellApplication {
    name = "immich_upload_google_takeout";
    runtimeInputs = with super.pkgs; [
      curl
      immich-go
      coreutils
      libnotify
    ];
    text = ''
      # 1. Input Validation
      if [ $# -eq 0 ]; then
        echo "Error: Please provide the path(s) to your Google Takeout archive(s)."
        echo "Usage: immich-import-takeout <part1.zip> <part2.zip>"
        echo "Or use globs: immich-import-takeout takeout-*.zip"
        exit 1
      fi

      # Verify every single file passed in the glob actually exists
      for file in "$@"; do
          if [ ! -f "$file" ]; then
              echo "Error: File '$file' not found."
              echo "If you used a glob like 'takeout-*.zip', make sure the files actually exist in this directory."
              exit 1
          fi
      done

      FILE_COUNT=$#
      echo "Starting Google Takeout import for $FILE_COUNT archive(s)..."

      # 2. Setup Variables and Secrets
      IMMICH_URL="http://hm90.tail7f031.ts.net:2283"
      PUSHOVER_USER=$(cat "/run/agenix/pushover_user")
      PUSHOVER_TOKEN=$(cat "/run/agenix/pushover_api_key")
      IMMICH_API_KEY=$(cat "/run/agenix/immich_api_key")

      # 3. Execute immich-go
      echo "Scanning and uploading archives to Immich..."

      # By passing "$@", bash expands all the files you provided into the immich-go command
      if immich-go upload from-google-photos --no-ui --server="$IMMICH_URL" --api-key="$IMMICH_API_KEY" --concurrent-tasks=12 --manage-burst=Stack --manage-raw-jpeg=StackCoverJPG "$@"; then
          TITLE="Takeout Import Complete ✅"
          MSG="Successfully parsed and uploaded $FILE_COUNT Takeout archive(s) to HM90."
          echo "$MSG"
          
          # 4. Bulk cleanup
          rm "$@"
          echo "Archives deleted."
      else
          TITLE="Takeout Import FAILED ⚠️"
          MSG="An error occurred while uploading the Takeout archives."
          echo "$MSG"
      fi

      # 5. Desktop Notification
      if command -v notify-send >/dev/null 2>&1; then
         notify-send "$TITLE" "$MSG"
      fi

      # 6. Pushover Notification
      curl -s \
        --form-string "token=$PUSHOVER_TOKEN" \
        --form-string "user=$PUSHOVER_USER" \
        --form-string "title=$TITLE" \
        --form-string "message=$MSG" \
        https://api.pushover.net/1/messages.json > /dev/null
    '';
  };
}
