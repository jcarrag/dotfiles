{
  pkgs,
  lib,
  config,
  ...
}:

let
  mergeArrPermissions =
    name: attrs:
    lib.recursiveUpdate {
      serviceConfig = {
        User = name;
        Group = name;
        # prevent systemd from making StateDirectory 0700
        UMask = lib.mkForce "0027";
        StateDirectoryMode = lib.mkForce "0750";
      };
    } attrs;
in
{
  # TODO authelia
  ##
  ##
  #### Syncthing backup (runs as james)
  users.users.james.extraGroups = [
    "dawarich"
    "immich"
    "lidarr"
    "aurral"
    "putioarr"
    "bazarr"
    "radarr"
    "sonarr"
    "seerr"
    "readarr"
    "audiobookshelf"
    "audiobookrequest"
    "podsync"
  ];
  fileSystems = {
    # TODO add lidarr
    # TODO add readarr
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
  #### Dawarich
  services.dawarich = {
    enable = true;
    configureNginx = false;
    database.passwordFile = config.age.secrets.dawarich_db_pass.path;
    localDomain = "dawarich.carragher.dev";
    webPort = 3001;
    environment = {
      APPLICATION_HOSTS = "100.65.97.33,hm90,hm90.tail7f031.ts.net,dawarich.carragher.dev";
      PHOTON_API_HOST = "photon.komoot.io";
      PHOTON_API_USE_HTTPS = "true";
      STORE_GEODATA = "true";
      # https://github.com/Freika/dawarich/issues/2570
      JWT_SECRET_KEY = "NOOP";
    };
  };

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
  systemd.services.immich-server.serviceConfig.UMask = lib.mkForce "0027";
  systemd.services.immich-machine-learning.serviceConfig.UMask = lib.mkForce "0027";

  ##
  ##
  #### slskd
  # FIXME give write access to lidarr to delete files in /var/lib/slskd/downloads
  services.slskd = {
    enable = true;
    domain = null;
    environmentFile = config.age.secrets.slskd_env.path;
    settings = {
      # start - deprecated in newer version
      global.upload.speed_limit = 1000; # KB
      permissions.file.mode = 775; # replaced with transfers.download.destination.permissions.mode
      # end - deprecated in newer version
      web = {
        ip_address = "100.65.97.33";
      };
      shares.directories = [
        "[music]/home/james/music-library/music"
      ];
      soulseek = {
        listen_port = 50300;
        connection.proxy = {
          enabled = true;
          address = "100.107.156.1";
          port = 1080;
        };
      };
      transfers = {
        upload = {
          slots = 1;
          speed_limit = 1000; # KB
        };
        download = {
          slots = 1;
          speed_limit = 1000; # KB
          destination.permissions.mode = 775; # lidarr:slskd needs to delete files
        };
      };
      retention = {
        search = 10080; # 7 days, in minutes
        transfers = {
          upload = {
            succeeded = 1440; # 1 day, in minutes
            errored = 30;
            cancelled = 5;
            failed = 180; # any unsuccessful transfer, including errored and cancelled
          };
          download = {
            succeeded = 1440; # 1 day, in minutes
            errored = 20160; # 2 weeks, in minutes
            cancelled = 5;
            failed = 180; # any unsuccessful transfer, including errored and cancelled
          };
        };
        files = {
          complete = 20160; # 2 weeks, in minutes
          incomplete = 43200; # 30 days, in minutes
        };
      };
    };
  };
  systemd.services.slskd = mergeArrPermissions "slskd" {
    serviceConfig.BindPaths = [ "/home/james/music-library/music" ];
    serviceConfig.ProtectHome = lib.mkForce "tmpfs";
    serviceConfig.UMask = lib.mkForce "0002";
  };

  ##
  ##
  #### Lidarr
  #### Remote linode access
  # fileSystems."/mnt/linode_downloads" = {
  #   device = "linode:/var/lib/slskd/downloads";
  #   fsType = "fuse.sshfs";
  #   options = [
  #     # don't hang the boot process waiting for the network
  #     "x-systemd.automount"
  #     "_netdev"
  #     # allow the lidarr users to see and read the files
  #     "allow_other"
  #     # map client-side file ownership to lidarr:lidarr
  #     # nb server-side uses the SSH user to validate perms, so linode#james must be in :slskd
  #     "uid=306,gid=306"
  #     # automatically accept the VPS host key on first connection
  #     "StrictHostKeyChecking=accept-new"
  #     # keep the connection alive and reconnect if the internet drops
  #     "ServerAliveInterval=15"
  #     "reconnect"
  #   ];
  # };
  users.groups.lidarr = {
    gid = 306;
  };
  users.users.lidarr = {
    isSystemUser = true;
    uid = 306;
    group = "lidarr";
    extraGroups = [
      "slskd"
    ];
    # Rootless podman needs a HOME for its per-user image store. It must NOT be
    # /var/lib/lidarr: that whole dir is bind-mounted as /config, which would both
    # expose the image store to the container and let the image's chown recurse into it.
    home = "/var/lib/podman-lidarr";
    createHome = true;
    linger = true;
    # Subuid/subgid starts are pinned to NixOS's own allocator grid (100000 + n*65536,
    # where james already holds 100000). That matters: the allocator only skips start
    # values it finds verbatim in /etc/subuid, and is blind to explicitly configured
    # ranges - so an off-grid range here would eventually be handed out again to a new
    # normal user, silently sharing subuids between two users and undoing the isolation.
    subUidRanges = [
      {
        startUid = 165536;
        count = 65536;
      }
    ];
    subGidRanges = [
      {
        startGid = 165536;
        count = 65536;
      }
    ];
  };
  virtualisation.oci-containers.containers.lidarr = {
    podman.user = "lidarr";
    serviceName = "lidarr";
    # To update (rootless - the image store belongs to the lidarr user now):
    # > sudo -u lidarr HOME=/var/lib/podman-lidarr XDG_RUNTIME_DIR=/run/user/306 \
    #     podman pull lscr.io/linuxserver/lidarr:nightly
    # To run from local:
    # > sudo podman build -t lidarr-local -f docker/Dockerfile .
    # image = "localhost/lidarr-local:nightly";
    image = "lscr.io/linuxserver/lidarr:nightly";
    extraOptions = [
      "--network=host"
    ];
    volumes = [
      "/var/lib/lidarr:/config"
      "/home/james/music-library/music:/data/music"
      # "/mnt/linode_downloads:/linode_downloads"
      "/var/lib/slskd/downloads:/var/lib/slskd/downloads"
    ];
    environment = {
      # Rootless: container uid 0 already maps to host uid 306 (lidarr), so run the
      # app as container-root to keep host-side files owned by lidarr:lidarr. A
      # non-zero PUID would land in the subuid range instead (306 -> 165841), breaking
      # the shared music-library/slskd-downloads permissions.
      PUID = "0";
      PGID = "0";
    };
  };
  # nb no mergeArrPermissions here: `podman.user` above already runs the unit as lidarr
  # (Group unset, so systemd uses lidarr's primary group), and there is no StateDirectory
  # for its StateDirectoryMode to apply to. Its UMask = mkForce "0027" would also collide
  # with the mkForce "0000" below - equal priority, and serviceConfig entries merge with
  # mergeEqualOption, so eval fails rather than one of them winning. The 0000 is
  # deliberate: it keeps group write on the files shared with slskd and james.
  systemd.services.lidarr = {
    serviceConfig.BindPaths = [ "/home/james/music-library/music" ];
    serviceConfig.ProtectHome = lib.mkForce "tmpfs";
    serviceConfig.UMask = lib.mkForce "0000";
  };

  ##
  ##
  #### Aurral
  users.groups.aurral = {
    gid = 5003;
  };
  users.users.aurral = {
    isSystemUser = true;
    uid = 5003;
    group = "aurral";
    # see the note on lidarr's home: keep the rootless image store out of /config
    home = "/var/lib/podman-aurral";
    description = "Aurral service user";
    createHome = true;
    linger = true;
    subUidRanges = [
      {
        startUid = 231072;
        count = 65536;
      }
    ];
    subGidRanges = [
      {
        startGid = 231072;
        count = 65536;
      }
    ];
    # TODO configure access to SABnzbd
    # nb this only affects host-side processes running as aurral. podman gives the
    # container no supplementary groups at all, so it does nothing for the container
    # itself - that needs extraOptions = [ "--group-add=306" ] below.
    extraGroups = [
      "lidarr" # so that aurral can access music/
    ];
  };
  virtualisation.oci-containers.containers.aurral = {
    podman.user = "aurral";
    serviceName = "aurral";
    image = "ghcr.io/lklynet/aurral:latest";
    ports = [
      "100.65.97.33:3003:3001"
      # FIXME use non-admin user for aurral
    ];
    volumes = [
      "/var/lib/aurral:/config"
      "/home/james/music-library:/data"
      # "/mnt/linode_downloads:/data/downloads/slskd/complete"
      # "/var/lib/slskd/downloads:/var/lib/slskd/downloads"
    ];
    environment = {
      # rootless: container uid 0 maps to host uid 5003 (aurral) - see lidarr
      PUID = "0";
      PGID = "0";
    };
  };
  # podman creates missing bind-mount targets itself, as root:root 01755 - and
  # /data/downloads/slskd/complete is nested inside the /data mount, so those dirs get
  # created on the host. Pre-create them owned by aurral so podman leaves them alone.
  # systemd.tmpfiles can't do this: it refuses to chase /home/james (james) ->
  # music-library (non-james) as an unsafe path transition.
  systemd.services.aurral = {
    # mkForce + both paths: rootless oci-containers also wants
    # RequiresMountsFor=/run/user/5003/containers, and a plain second definition of
    # this option is a merge conflict rather than a union.
    unitConfig.RequiresMountsFor = lib.mkForce "/home/james/music-library /run/user/5003/containers";
    serviceConfig.ExecStartPre = lib.mkBefore [
      (pkgs.writeShellScript "aurral-prepare-dirs" ''
        ${pkgs.coreutils}/bin/install -d -o aurral -g aurral -m 2775 \
          /home/james/music-library/downloads \
          /home/james/music-library/downloads/aurral \
          /home/james/music-library/downloads/slskd \
          /home/james/music-library/downloads/slskd/complete
      '').outPath
    ];
  };

  ##
  ##
  #### Navidrome
  services.navidrome = {
    enable = true;
    settings = {
      Address = "100.65.97.33";
      MusicFolder = "/home/james/music-library/music";
    };
  };
  users.users.navidrome = {
    isSystemUser = true;
    group = "navidrome";
  };
  # TODO add PasswordEncryptionKey (https://www.navidrome.org/docs/usage/admin/security/)
  users.groups.navidrome = { };
  systemd.services.navidrome = mergeArrPermissions "navidrome" {
    serviceConfig.BindPaths = [ "/home/james/music-library/music" ];
    serviceConfig.ProtectHome = lib.mkForce "tmpfs";
  };

  ##
  ##
  #### Remote deluge access
  programs.fuse.userAllowOther = true;
  programs.ssh.extraConfig = ''
    Include ${config.age.secrets.deluge_ssh_config.path}
    Include ${config.age.secrets.linode_ssh_config.path}
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
  systemd.services.seerr = mergeArrPermissions "seerr" { };

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
  systemd.services.prowlarr = mergeArrPermissions "prowlarr" { };

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
  # audiobookshelf refuses to fetch podcast feeds from non-unicast addresses (it wraps
  # axios in ssrf-req-filter), and tailscale addresses are in the 100.64.0.0/10 CGNAT
  # range - so adding the podsync feed fails with "Call to 100.65.97.33 is blocked".
  # Whitelist just the hosts involved rather than DISABLE_SSRF_REQUEST_FILTER=1, which
  # would turn the filter off for every URL.
  # nb the enclosure URLs in the feed use podsync's server.hostname, and episode
  # downloads go through the same filter - so that name has to be listed too, otherwise
  # the feed parses but every episode download is blocked. Matching is on exact hostname.
  systemd.services.audiobookshelf.environment.SSRF_REQUEST_FILTER_WHITELIST =
    builtins.concatStringsSep ","
      [
        "100.65.97.33" # podsync feed url
        "hm90.tail7f031.ts.net" # podsync server.hostname, used by the episode enclosures
        "hm90"
      ];

  users.groups.audiobookrequest = {
    gid = 5001;
  };
  users.users.audiobookrequest = {
    isSystemUser = true;
    uid = 5001;
    group = "audiobookrequest";
    description = "AudioBookRequest service user";
    # rootless podman image store; /var/lib/audiobookrequest is the /config volume
    home = "/var/lib/podman-audiobookrequest";
    createHome = true;
    linger = true;
    subUidRanges = [
      {
        startUid = 362144;
        count = 65536;
      }
    ];
    subGidRanges = [
      {
        startGid = 362144;
        count = 65536;
      }
    ];
  };
  virtualisation.oci-containers.containers.audiobookrequest = {
    podman.user = "audiobookrequest";
    serviceName = "audiobookrequest";
    # experimental support for readarr
    # > git fetch origin pull/191/head:pr-191 && git checkout pr-191
    # > sudo podman build -t markbeep/audiobookrequest:pr-191 .
    image = "markbeep/audiobookrequest:pr-191";
    # image = "markbeep/audiobookrequest:latest";
    extraOptions = [
      "--network=host"
      # The manual "--uidmap=0:5001"/"--gidmap=0:5001" pair is gone: under rootless
      # podman container uid/gid 0 already maps to the running user (audiobookrequest,
      # 5001), which is exactly what those flags were emulating. Keeping them would
      # fail - a rootless uidmap target must fall inside the user's subuid range.
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
  #### Podsync
  users.groups.podsync = {
    gid = 5004;
  };
  users.users.podsync = {
    isSystemUser = true;
    uid = 5004;
    group = "podsync";
    description = "podsync service user";
    # rootless podman image store; the container mounts individual /var/lib/podsync
    # paths, so keep the store out of the way in its own directory
    home = "/var/lib/podman-podsync";
    createHome = true;
    linger = true;
    subUidRanges = [
      {
        startUid = 427680;
        count = 65536;
      }
    ];
    subGidRanges = [
      {
        startGid = 427680;
        count = 65536;
      }
    ];
  };
  system.activationScripts."podsync_write_config" = {
    deps = [ "users" ];
    text =
      let
        podsync-config = (pkgs.formats.toml { }).generate "config.toml" {
          server = {
            port = 9092;
            bind_address = "100.65.97.33";
            # episode enclosure links in the generated RSS point here, so it has to be
            # an address the podcast client can reach - not localhost
            hostname = "http://hm90.tail7f031.ts.net:9092";
            web_ui = true;
          };
          storage = {
            type = "local";
            # container paths, see the volume mounts below
            local.data_dir = "/app/data";
          };
          database.dir = "/app/db";
          # https://developers.google.com/youtube/registering_an_application
          tokens.youtube = "@podsync_youtube_api_key@";
          downloader = {
            # the image bundles a youtube-dl that goes stale (youtube then rejects the
            # download with "content is not available on this app"), and its self_update
            # rewrites /usr/local/bin inside the container - so the update is lost on
            # every container recreate, and blocks startup re-downloading it. Pin the
            # nixpkgs one instead; podsync turns self updates off for a custom binary.
            # Bump with `nix flake update unstable` when youtube breaks extraction again.
            custom_binary = "${pkgs.unstable.yt-dlp}/bin/yt-dlp";
            timeout = 15; # minutes
          };
          # keep_last for feeds that don't set their own clean policy
          cleanup.keep_last = 20;
          feeds = {
            audio_rss = {
              url = "https://www.youtube.com/playlist?list=@podsync_playlist_id@";
              private_feed = true;
              page_size = 20;
              update_period = "12h";
              format = "audio";
              quality = "high";
              opml = true;
              clean.keep_last = 100;
            };
          };
        };
      in
      pkgs.lib.mkForce ''
        mkdir -p /var/lib/podsync
        cp ${podsync-config} /var/lib/podsync/config.toml
        chown podsync:podsync /var/lib/podsync/config.toml
        chmod 400 /var/lib/podsync/config.toml
      '';
  };
  virtualisation.oci-containers.containers.podsync = {
    podman.user = "podsync";
    serviceName = "podsync";
    # To update (rootless - the image store belongs to the podsync user now):
    # > sudo -u podsync HOME=/var/lib/podman-podsync XDG_RUNTIME_DIR=/run/user/5004 \
    #     podman pull ghcr.io/mxpv/podsync:latest
    image = "ghcr.io/mxpv/podsync:latest";
    extraOptions = [
      "--network=host"
      # nb not a linuxserver image, so PUID/PGID do nothing here. The container runs as
      # root, which rootless podman already maps to podsync (5004) on the host.
    ];
    volumes = [
      "/var/lib/podsync/config.toml:/app/config.toml:ro"
      "/var/lib/podsync/data:/app/data"
      "/var/lib/podsync/db:/app/db"
      # podsync downloads to /tmp before moving into data_dir, so without this the
      # full-size media transits the container's overlay
      "/var/lib/podsync/tmp:/tmp"
      # needed by downloader.custom_binary above - the nixpkgs yt-dlp is a wrapper
      # script that execs bash/python out of the store
      "/nix/store:/nix/store:ro"
    ];
    environment = {
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
    # rootless podman image store; /var/lib/putioarr is the /config volume
    home = "/var/lib/podman-putioarr";
    createHome = true;
    linger = true;
    subUidRanges = [
      {
        startUid = 296608;
        count = 65536;
      }
    ];
    subGidRanges = [
      {
        startGid = 296608;
        count = 65536;
      }
    ];
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
          # nb this must be identical to the host path. putioarr decides a transfer has
          # been imported by string-comparing its own download target against the
          # droppedPath in the *arr history, and the *arr reports the host path. With
          # container-only paths (/downloads/...) plus a remote path mapping the two
          # never match, so putioarr waits out its import window and never cleans up.
          download_directory = "/var/lib/putioarr/downloads";
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
    podman.user = "putioarr";
    serviceName = "putioarr";
    # To update (rootless - image store belongs to the putioarr user now):
    # > sudo -u putioarr HOME=/var/lib/podman-putioarr XDG_RUNTIME_DIR=/run/user/5002 \
    #     podman pull ghcr.io/wouterdebie/putioarr:latest
    # To run from local:
    # > sudo podman build -t putioarr-local -f docker/Dockerfile .
    # image = "localhost/putioarr-local:latest";
    image = "ghcr.io/wouterdebie/putioarr:latest";
    extraOptions = [
      "--network=host"
    ];
    volumes = [
      "/var/lib/putioarr:/config"
      # mounted at the same path inside the container, see download_directory above
      "/var/lib/putioarr/downloads:/var/lib/putioarr/downloads"
    ];
    environment = {
      # rootless: container uid 0 maps to host uid 5002 (putioarr) - see lidarr
      PUID = "0";
      PGID = "0";
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
  systemd.services.bazarr = mergeArrPermissions "bazarr" {
    serviceConfig.BindPaths = [ "/home/james/emby-library" ];
    serviceConfig.ProtectHome = lib.mkForce "tmpfs";
    # 0027 would strip group write from the subtitles bazarr writes into emby-library
    serviceConfig.UMask = lib.mkForce "0002";
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
  systemd.services.sonarr = mergeArrPermissions "sonarr" {
    serviceConfig.BindPaths = [ "/home/james/emby-library" ];
    serviceConfig.ProtectHome = lib.mkForce "tmpfs";
    # deliberately looser than the 0027 above: both it and the 0022 default make new
    # show/season dirs drwxr-sr-x, so bazarr cannot write subtitles next to the episodes
    serviceConfig.UMask = lib.mkForce "0002";
  };

  # by default sonarr/bazarr/radarr group members cannot access dataDir, change so that syncthing can access
  systemd.tmpfiles.rules = [
    "Z  /var/lib/immich 0750 immich immich - -"

    "Z  /var/lib/putioarr 0770 putioarr putioarr - -"

    "d  /var/lib/podsync 0750 podsync podsync - -"
    "d  /var/lib/podsync/data 0750 podsync podsync - -"
    "d  /var/lib/podsync/db 0750 podsync podsync - -"
    "d  /var/lib/podsync/tmp 0750 podsync podsync - -"

    "Z /var/lib/slskd/downloads 2775 slskd lidarr - -" # ensure lidarr can delete from slskd download dir

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
  systemd.services.radarr = mergeArrPermissions "radarr" {
    serviceConfig.BindPaths = [ "/home/james/emby-library" ];
    serviceConfig.ProtectHome = lib.mkForce "tmpfs";
    # deliberately looser than the 0027 above: both it and the 0022 default make new
    # show/season dirs drwxr-sr-x, so bazarr cannot write subtitles next to the episodes
    serviceConfig.UMask = lib.mkForce "0002";
  };

  ##
  ##
  #### Sabnzbd
  systemd.services.sabnzbd = {
    after = [
      "network-online.target"
      "tailscaled.service"
    ];
    wants = [
      "network-online.target"
      "tailscaled.service"
    ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStartPre = pkgs.tailscaleWaitOnline;
    };
  };
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
