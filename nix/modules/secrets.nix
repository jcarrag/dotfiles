{
  pkgs,
  config,
  lib,
  ...
}:

let
  hostName = config.networking.hostName;
  mk-age =
    {
      name,
      owner,
      group ? owner,
      mode ? "",
    }:
    {
      inherit name;
      value = {
        inherit owner group;
        file = ../secrets/${name}.age;
      }
      // lib.optionalAttrs (mode != "") {
        inherit mode;
      };
    };
  mk-activation =
    {
      name,
      sedConfigFile,
      deps ? [ ],
    }:
    {
      inherit name;
      value = {
        text = ''
          secret=$(cat "${config.age.secrets.${name}.path}")
          configFile=${sedConfigFile}
          ${pkgs.gnused}/bin/sed -i "s#@${name}@#$secret#" "$configFile"
        '';

      }
      // lib.optionalAttrs (deps != [ ]) {
        inherit deps;
      };
    };
in
{
  age = {
    identityPaths = [
      # The on-disk user key is kept only so `agenix -e/-r` can run from a
      # laptop; the 1Password SSH agent can't serve it (no agent support in
      # age). https://github.com/ryantm/agenix/pull/451 adds an opt-in
      # age-plugin-sshagent workflow -- when it lands, re-encrypt to the
      # plugin recipient, drop this path and delete ~/.ssh/id_ed25519.
      (pkgs.throwAfterDate "2027-03-28" "/home/james/.ssh/id_ed25519")
      # Host keys: what activation actually decrypts with.
      "/etc/ssh/ssh_host_ed25519_key"
    ];
    secrets = builtins.listToAttrs (
      map mk-age (
        if hostName == "hm90" then
          [
            {
              name = "dawarich_db_pass";
              owner = "dawarich";
            }
            {
              name = "putioarr_pass";
              owner = "putioarr";
            }
            {
              name = "putio_api_key";
              owner = "putioarr";
            }
            {
              name = "podsync_youtube_api_key";
              owner = "podsync";
            }
            {
              name = "podsync_playlist_id";
              owner = "podsync";
            }
            {
              name = "sonarr_api_key";
              owner = "putioarr";
            }
            {
              name = "radarr_api_key";
              owner = "putioarr";
            }
            {
              name = "sabnzbd_api_key";
              owner = "sabnzbd";
            }
            {
              name = "sabnzbd_frugal_user";
              owner = "sabnzbd";
            }
            {
              name = "sabnzbd_frugal_pass";
              owner = "sabnzbd";
            }
            {
              name = "sabnzbd_eweka_user";
              owner = "sabnzbd";
            }
            {
              name = "sabnzbd_eweka_pass";
              owner = "sabnzbd";
            }
            {
              name = "sabnzbd_blocknews_user";
              owner = "sabnzbd";
            }
            {
              name = "sabnzbd_blocknews_pass";
              owner = "sabnzbd";
            }
            {
              name = "slskd_env";
              owner = "slskd";
            }
            {
              name = "kavita_token_key";
              owner = "kavita";
            }
            {
              # readeck runs with DynamicUser, systemd reads the EnvironmentFile as root
              name = "readeck_env";
              owner = "root";
            }
            {
              name = "deluge_ssh_config";
              owner = "root";
              mode = "0444";
            }
            {
              name = "linode_ssh_config";
              owner = "root";
              mode = "0444";
            }
            {
              name = "pushover_user";
              owner = "james";
              group = "users";
            }
            {
              name = "pushover_api_key";
              owner = "james";
              group = "users";
            }
            {
              name = "immich_api_key";
              owner = "james";
              group = "users";
            }
            {
              name = "frigate_number_plates";
              owner = "frigate";
              group = "frigate";
            }
          ]
        else if hostName == "lunar-fwk" || hostName == "fwk" then
          [
            {
              name = "pushover_user";
              owner = "james";
              group = "users";
            }
            {
              name = "pushover_api_key";
              owner = "james";
              group = "users";
            }
            {
              name = "immich_api_key";
              owner = "james";
              group = "users";
            }
          ]
        else
          [ ]
      )
    );
  };
  # These sometimes need two `nixos-rebuild switch` to run
  system.activationScripts = builtins.listToAttrs (
    map mk-activation (
      if hostName == "hm90" then
        [
          {
            name = "putioarr_pass";
            sedConfigFile = "/var/lib/putioarr/config.toml";
            deps = [ "putioarr_write_config" ];
          }
          {
            name = "putio_api_key";
            sedConfigFile = "/var/lib/putioarr/config.toml";
            deps = [ "putioarr_write_config" ];
          }
          {
            name = "podsync_youtube_api_key";
            sedConfigFile = "/var/lib/podsync/config.toml";
            deps = [ "podsync_write_config" ];
          }
          {
            name = "podsync_playlist_id";
            sedConfigFile = "/var/lib/podsync/config.toml";
            deps = [ "podsync_write_config" ];
          }
          {
            name = "sonarr_api_key";
            sedConfigFile = "/var/lib/putioarr/config.toml";
            deps = [ "putioarr_write_config" ];
          }
          {
            name = "radarr_api_key";
            sedConfigFile = "/var/lib/putioarr/config.toml";
            deps = [ "putioarr_write_config" ];
          }
        ]
      else
        [ ]
    )
  );
}
