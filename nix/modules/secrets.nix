{
  pkgs,
  config,
  lib,
  ...
}:

let
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
      "/home/james/.ssh/id_ed25519"
      "/etc/ssh/ssh_host_ed25519_key"
    ];
    secrets = builtins.listToAttrs (
      map mk-age [
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
          name = "deluge_ssh_config";
          owner = "root";
          mode = "0444";
        }
      ]
    );
  };
  # These sometimes need two `nixos-rebuild switch` to run
  system.activationScripts = builtins.listToAttrs (
    map mk-activation [
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
        name = "sonarr_api_key";
        sedConfigFile = "/var/lib/putioarr/config.toml";
        deps = [ "putioarr_write_config" ];
      }
      {
        name = "radarr_api_key";
        sedConfigFile = "/var/lib/putioarr/config.toml";
        deps = [ "putioarr_write_config" ];
      }
      {
        name = "sabnzbd_api_key";
        sedConfigFile = "/var/lib/sabnzbd/sabnzbd.ini";
      }
      {
        name = "sabnzbd_frugal_user";
        sedConfigFile = "/var/lib/sabnzbd/sabnzbd.ini";
      }
      {
        name = "sabnzbd_frugal_pass";
        sedConfigFile = "/var/lib/sabnzbd/sabnzbd.ini";
      }
      {
        name = "sabnzbd_eweka_user";
        sedConfigFile = "/var/lib/sabnzbd/sabnzbd.ini";
      }
      {
        name = "sabnzbd_eweka_pass";
        sedConfigFile = "/var/lib/sabnzbd/sabnzbd.ini";
      }
      {
        name = "sabnzbd_blocknews_user";
        sedConfigFile = "/var/lib/sabnzbd/sabnzbd.ini";
      }
      {
        name = "sabnzbd_blocknews_pass";
        sedConfigFile = "/var/lib/sabnzbd/sabnzbd.ini";
      }
    ]
  );
}
