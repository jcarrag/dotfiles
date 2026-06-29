{
  config,
  pkgs,
  lib,
  ...
}:

let
  immichUrl = "http://hm90.tail7f031.ts.net:2283";

  cameraSyncScript = pkgs.writeShellApplication {
    name = "immich-camera-sync";
    runtimeInputs = with pkgs; [
      curl
      immich-go
      coreutils
      gnugrep
      gphoto2
    ];
    text = ''
            echo "Udev event caught: Initiating secure immich-go sync..."

            PUSHOVER_USER=$(cat "$CREDENTIALS_DIRECTORY/pushover_user")
            PUSHOVER_TOKEN=$(cat "$CREDENTIALS_DIRECTORY/pushover_api_key")
            IMMICH_API_KEY=$(cat "$CREDENTIALS_DIRECTORY/immich_api_key")
      # FIXME do rest

            if ! curl -s --connect-timeout 3 "${immichUrl}/api/ping" > /dev/null; then
                echo "Error: HM90 Server unreachable. Aborting to protect camera data."
                exit 1
            fi

            if ! gphoto2 --auto-detect | grep -q "Canon EOS M100"; then
                echo "Error: Canon camera detected by udev, but not responding to gphoto2."
                exit 1
            fi

            STAGING_DIR="$RUNTIME_DIRECTORY"
            mkdir -p "$STAGING_DIR"
            cd "$STAGING_DIR"

            echo "Downloading images from Canon M100 to staging area..."
            gphoto2 --get-all-files --recurse

            # Count local files downloaded to verify staging isn't empty
            FILE_COUNT=$(find . -type f | wc -l)
            if [ "$FILE_COUNT" -eq 0 ]; then
                echo "No files found on camera to download. Exiting cleanly."
                exit 0
            fi

            echo "Uploading $FILE_COUNT files to Immich server via immich-go..."

            if immich-go upload from-folder --server="${immichUrl}" --api-key="$IMMICH_API_KEY" "$STAGING_DIR"; then
                echo "UPLOAD SUCCESSFUL! Proceeding to clear camera storage..."

                # Safe Delete: Only executes if immich-go exit status is 0
      # FIXME: uncomment
                gphoto2 --delete-all-files --recurse

                MSG="Successfully synced $FILE_COUNT photos via immich-go and cleared the Canon M100 storage card."
                TITLE="Immich Sync Complete 📸"
                MSG="Uploaded $FILE_COUNT photos & videos."
            else
                echo "ERROR: immich-go upload failed or interrupted. Camera storage untouched."
                MSG="Downloaded photos from camera, but immich-go failed to push them to HM90. Photos remain safe on your camera card."
                TITLE="Immich Sync FAILED ⚠️"
            fi

            curl -s \
              --form-string "token=$PUSHOVER_TOKEN" \
              --form-string "user=$PUSHOVER_USER" \
              --form-string "title=$TITLE" \
              --form-string "message=$MSG" \
              https://api.pushover.net/1/messages.json > /dev/null
    '';
  };
in
{
  users.groups.immich-camera-sync = { };
  systemd.services.immich-camera-sync = {
    description = "Offload images from camera via API to remote server using immich-go";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${lib.getExe cameraSyncScript}";
      DynamicUser = "yes";
      RunTimeDirectory = "immich-camera-sync";
      # don't deny access to USB devices
      PrivateDevices = false;
      # group that has access to camera USB device
      SupplementaryGroups = [ "immich-camera-sync" ];
      LoadCredential = [
        "pushover_user:${config.age.secrets.pushover_user.path}"
        "pushover_api_key:${config.age.secrets.pushover_api_key.path}"
        "immich_api_key:${config.age.secrets.immich_api_key.path}"
      ];
    };
  };

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="04a9", ATTR{idProduct}=="32d1", GROUP="immich-camera-sync", MODE="0660", TAG+="systemd", ENV{SYSTEMD_WANTS}="immich-camera-sync.service"
  '';
}
