{
  pkgs,
  lib,
  config,
  ...
}:

let
  arrPermissions = name: {
    serviceConfig = {
      User = name;
      Group = name;
      # prevent systemd from making StateDirectory 0700
      UMask = lib.mkForce "0027";
      StateDirectoryMode = lib.mkForce "0750";
    };
  };
in
{
  ##
  ##
  #### Syncthing backup (runs as james)
  users.users.james.extraGroups = [
    "immich"
    "putioarr"
    "bazarr"
    "radarr"
    "sonarr"
    "seerr"
    "readarr"
    "audiobookshelf"
    "audiobookrequest"
  ];
  fileSystems = {
    # TODO add emby-server
    # TODO add readarr
    # TODO add putioarr
    # TODO add audiobookrequest
    # TODO add audiobookshelf
    "/home/james/arr_backup/immich" = {
      device = "/var/lib/immich";
      options = [ "bind" ];
      fsType = "none";
    };
    "/home/james/arr_backup/bazarr/backup" = {
      device = "/var/lib/bazarr";
      options = [ "bind" ];
      fsType = "none";
    };
    "/home/james/arr_backup/sonarr" = {
      device = "/var/lib/sonarr/.config/NzbDrone/Backups";
      options = [ "bind" ];
      fsType = "none";
    };
    "/home/james/arr_backup/radarr" = {
      device = "/var/lib/radarr/.config/Radarr/Backups";
      options = [ "bind" ];
      fsType = "none";
    };
    "/home/james/arr_backup/jellyseerr" = {
      device = "/var/lib/jellyseerr";
      options = [ "bind" ];
      fsType = "none";
    };
  };

  users.users.emby-server.extraGroups = [
    "bazarr" # to read bazarr files
    "sonarr" # to read sonarr files
    "radarr" # to read radarr files
    "readarr" # to read readarr files
  ];

  ##
  ##
  #### Immich
  services.immich = {
    enable = true;
    host = "100.65.97.33";
    settings = {
      server.externalDomain = "https://ipp.carragher.dev";
    };
  };
  services.immich-public-proxy = {
    enable = true;
    immichUrl = "http://100.65.97.33:2283";
  };

  ##
  ##
  #### Remote deluge access
  programs.fuse.userAllowOther = true;
  programs.ssh.extraConfig = ''
    Include ${config.age.secrets.deluge_ssh_config.path}
  '';
  fileSystems."/mnt/vps_downloads" = {
    device = "deluge:/home10/venbede/downloads/deluge/done";
    fsType = "fuse.sshfs";
    options = [
      # don't hang the boot process waiting for the network
      "x-systemd.automount"
      "_netdev"
      # allow the sonarr/radarr users to see and read the files
      "allow_other"
      # automatically accept the VPS host key on first connection
      "StrictHostKeyChecking=accept-new"
      # keep the connection alive and reconnect if the internet drops
      "ServerAliveInterval=15"
      "reconnect"
    ];
  };

  ##
  ##
  #### Seerr (previously jellyseerr)
  services.seerr = {
    enable = true;
  };
  users.users.seerr = {
    isSystemUser = true;
    group = "seerr";
  };
  users.groups.seerr = { };
  systemd.services.seerr = arrPermissions "seerr";

  ##
  ##
  #### Prowlarr
  services.prowlarr = {
    enable = true;
  };
  users.users.prowlarr = {
    isSystemUser = true;
    group = "prowlarr";
  };
  users.groups.prowlarr = { };
  systemd.services.prowlarr = arrPermissions "prowlarr";

  ##
  ##
  #### Readarr + audiobookrequest + audiobookshelf
  services.readarr = {
    enable = true;
  };
  users.users.readarr.extraGroups = [
    "emby-server" # access to emby-library
    "sabnzbd" # access to sabnzbd downloads dir
  ];
  services.audiobookshelf = {
    enable = true;
    port = 6363;
    host = "100.65.97.33";
  };
  users.users.audiobookshelf.extraGroups = [
    "emby-server" # access to emby-library
    "readarr" # access to files created by readarr
  ];

  users.groups.audiobookrequest = {
    gid = 5001;
  };
  users.users.audiobookrequest = {
    isSystemUser = true;
    uid = 5001;
    group = "audiobookrequest";
    description = "AudioBookRequest service user";
    createHome = false;
  };
  virtualisation.oci-containers.containers.audiobookrequest = {
    serviceName = "audiobookrequest";
    # experimental support for readarr
    # > git fetch origin pull/191/head:pr-191 && git checkout pr-191
    # > sudo podman build -t markbeep/audiobookrequest:pr-191 .
    image = "markbeep/audiobookrequest:pr-191";
    # image = "markbeep/audiobookrequest:latest";
    extraOptions = [
      "--network=host"
      # map container's user (root) to host's user (audiobookrequest)
      "--uidmap=0:5001"
      "--gidmap=0:5001"
    ];
    volumes = [
      "/var/lib/audiobookrequest:/config"
    ];
    environment = {
      ABR_APP__PORT = "6464";
      TZ = "Europe/London";
    };
  };

  ##
  ##
  #### Putioarr
  users.groups.putioarr = {
    gid = 5002;
  };
  users.users.putioarr = {
    isSystemUser = true;
    uid = 5002;
    group = "putioarr";
    description = "putioarr service user";
    createHome = false;
  };
  # serviceConfig = {
  #   # prevent systemd from making StateDirectory 0700
  #   UMask = lib.mkForce "0007";
  #   StateDirectoryMode = lib.mkForce "0770";
  # };
  system.activationScripts."putioarr_write_config" = {
    deps = [ "users" ];
    text =
      let
        putio-config = (pkgs.formats.toml { }).generate "config.toml" {
          username = "putioarr";
          password = "@putioarr_pass@";
          download_directory = "/downloads";
          bind_address = "100.65.97.33";
          port = 9091;
          # debug settings
          # loglevel = "debug";
          # polling_interval = 60;
          # orchestration_workers = 1;
          # download_workers = 1;

          # > cargo install putioarr && putioarr get-token
          putio.api_key = "@putio_api_key@";
          sonarr = {
            url = "http://hm90.tail7f031.ts.net:8989";
            api_key = "@sonarr_api_key@";
            category = "tv";
          };
          radarr = {
            url = "http://hm90.tail7f031.ts.net:7878";
            api_key = "@radarr_api_key@";
            category = "movies";
          };
        };
      in
      pkgs.lib.mkForce ''
        mkdir -p /var/lib/putioarr
        cp ${putio-config} /var/lib/putioarr/config.toml
        chown putioarr:putioarr /var/lib/putioarr/config.toml
        chmod 400 /var/lib/putioarr/config.toml
      '';
  };
  virtualisation.oci-containers.containers.putioarr = {
    serviceName = "putioarr";
    # To update:
    # > sudo podman pull putioarr:latest
    # To run from local:
    # > sudo podman build -t putioarr-local -f docker/Dockerfile .
    # image = "localhost/putioarr-local:latest";
    image = "ghcr.io/wouterdebie/putioarr:latest";
    extraOptions = [
      "--network=host"
    ];
    volumes = [
      "/var/lib/putioarr:/config"
      "/var/lib/putioarr/downloads:/downloads"
    ];
    environment = {
      PUID = "5002";
      PGID = "5002";
      UMASK = "007";
      UMASK_SET = "007";
      TZ = "Europe/London";
    };
  };

  ##
  ##
  #### Bazarr
  services.bazarr = {
    enable = true;
  };
  # bazarr uses nobody:nogroup by default, so set a user:group so syncthing can be added to group
  users.users.bazarr = {
    isSystemUser = true;
    group = "bazarr";
    extraGroups = [
      "emby-server" # access to emby-library
      "sonarr" # access to files in emby-library that were downloaded by sonarr
      "radarr" # access to files in emby-library that were downloaded by radarr
    ];
  };
  users.groups.bazarr = { };
  systemd.services.bazarr = arrPermissions "bazarr" // {
    serviceConfig.BindPaths = [ "/home/james/emby-library" ];
    serviceConfig.ProtectHome = lib.mkForce "tmpfs";
  };

  ##
  ##
  #### Sonarr
  services.sonarr = {
    enable = true;
  };
  users.users.sonarr.extraGroups = [
    "emby-server" # access to emby-library
    "sabnzbd" # access to sabnzbd downloads dir
    "putioarr" # access to putioarr downloads dir
  ];
  # by default UMask is 0022 which prevents group members from writing, but bazarr needs to write to sonarr dirs in emby-server/
  # systemd.services.sonarr.serviceConfig.UMask = lib.mkForce "0002";
  systemd.services.sonarr = arrPermissions "sonarr" // {
    serviceConfig.BindPaths = [ "/home/james/emby-library" ];
    serviceConfig.ProtectHome = lib.mkForce "tmpfs";
  };

  # by default sonarr/bazarr/radarr group members cannot access dataDir, change so that syncthing can access
  systemd.tmpfiles.rules = [
    "Z  /var/lib/immich 0750 immich immich - -"

    "Z  /var/lib/putioarr 0770 putioarr putioarr - -"

    "A+ /var/lib/bazarr - - - - group:bazarr:r-x"
    "a+ /var/lib/bazarr - - - - group:bazarr:r-x"
    "Z  /var/lib/bazarr 0750 bazarr bazarr - -"

    "A+ /var/lib/sonarr - - - - group:sonarr:r-x"
    "a+ /var/lib/sonarr - - - - group:sonarr:r-x"
    "Z  /var/lib/sonarr 0750 sonarr sonarr - -"

    "A+ /var/lib/radarr - - - - group:radarr:r-x"
    "a+ /var/lib/radarr - - - - group:radarr:r-x"
    "Z  /var/lib/radarr 0750 radarr radarr - -"

    "A+ /var/lib/readarr - - - - group:readarr:r-x"
    "a+ /var/lib/readarr - - - - group:readarr:r-x"
    "Z  /var/lib/readarr 0750 readarr readarr - -"

    "d /var/lib/audiobookrequest 0777 audiobookrequest audiobookrequest -"
    "A+ /var/lib/audiobookrequest - - - - group:audiobookrequest:rwx"
    "a+ /var/lib/audiobookrequest - - - - group:audiobookrequest:rwx"
  ];

  ##
  ##
  #### Radarr
  services.radarr = {
    enable = true;
  };
  users.users.radarr.extraGroups = [
    "emby-server" # access to emby-library
    "sabnzbd" # access to sabnzbd downloads dir
    "putioarr" # access to putioarr downloads dir
  ];
  # by default UMask is 0022 which prevents group members from writing, but bazarr needs to write to radarr dirs in emby-server/
  # systemd.services.radarr.serviceConfig.UMask = lib.mkForce "0002";
  systemd.services.radarr = arrPermissions "radarr" // {
    serviceConfig.BindPaths = [ "/home/james/emby-library" ];
    serviceConfig.ProtectHome = lib.mkForce "tmpfs";
  };

  ##
  ##
  #### Sabnzbd
  services.sabnzbd = {
    enable = true;
    settings = {
      misc = {
        host = "100.65.97.33";
        port = 8090;
        local_ranges = "100.102.227.124/32,100.124.115.79/32,100.65.97.33/32";
        api_key = "@sabnzbd_api_key@";
        inet_exposure = 2; # allow access from network
        download_dir = "/var/lib/sabnzbd/downloading";
        complete_dir = "/var/lib/sabnzbd/complete";
        log_dir = "/var/lib/sabnzbd/logs";
        admin_dir = "/var/lib/sabnzbd/admin";
        backup_dir = "/var/lib/sabnzbd/backup";
        permissions = 770;
      };
      servers = {
        frugal = {
          enable = 1;
          name = "frugal";
          host = "eunews.frugalusenet.com";
          ssl = 1;
          port = 563;
          username = "@sabnzbd_frugal_user@";
          password = "@sabnzbd_frugal_pass@";
          connections = 20;
          priority = 0;
        };
        eweka = {
          enable = 1;
          name = "eweka";
          host = "news.eweka.nl";
          ssl = 1;
          port = 563;
          username = "@sabnzbd_eweka_user@";
          password = "@sabnzbd_eweka_pass@";
          connections = 20;
          priority = 1;
        };
        blocknews = {
          enable = 1;
          name = "blocknews";
          host = "eunews.blocknews.net";
          ssl = 1;
          port = 563;
          username = "@sabnzbd_blocknews_user@";
          password = "@sabnzbd_blocknews_pass@";
          connections = 40;
          priority = 2;
        };
      };
      categories = {
        "*" = {
          name = "*";
          order = 0;
          pp = 3;
          script = "None";
          dir = "";
          newzbin = "";
          priority = 0;
        };
        movies = {
          name = "movies";
          order = 0;
          pp = "";
          script = "Default";
          dir = "movies";
          newzbin = "";
          priority = -100;
        };
        tv = {
          name = "tv";
          order = 0;
          pp = "";
          script = "Default";
          dir = "tv";
          newzbin = "";
          priority = -100;
        };
        readarr = {
          name = "readarr";
          order = 0;
          pp = "";
          script = "Default";
          dir = "readarr";
          newzbin = "";
          priority = -100;
        };
        audio = {
          name = "audio";
          order = 0;
          pp = "";
          script = "Default";
          dir = "audio";
          newzbin = "";
          priority = -100;
        };
      };
    };
  };
}
