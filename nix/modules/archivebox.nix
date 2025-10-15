{
  lib,
  pkgs,
  config,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    archivebox
  ];

  # nixpkgs.config.permittedInsecurePackages = [
  #   "python3.12-django-3.1.14"
  # ];

  networking = {
    firewall = {
      interfaces.tailscale0 = {
        allowedTCPPorts = [
          8765 # webdav
          8766 # archivebox
        ];
      };
    };
  };

  systemd.services.webdav.after = pkgs.tailscaleAfter;
  systemd.services.webdav.wantedBy = pkgs.tailscaleWantedBy;
  systemd.services.webdav.serviceConfig.ExecStartPre = pkgs.tailscaleWaitOnline;
  services.webdav = {
    enable = true;
    user = "james";
    group = "users";
    settings = {
      address = "100.65.97.33";
      port = 8765;
      users = [
        {
          username = "tailscale";
          password = "{bcrypt}$2a$10$IpwXDJqyZpUAjzNo4UFlwOblcZTU4BZjK/E23EYinOrzzZPYGH.ci";
          permissions = "CRUD";
          directory = "/home/james/bookmarks_sync/floccus_webdav";
        }
      ];

    };
  };

  systemd.user.services.archivebox = {
    description = "Archivebox server service";
    environment = {
      BIND_ADDR = "100.65.97.33:8766";
    };
    after = pkgs.tailscaleAfter;
    wantedBy = pkgs.tailscaleWantedBy;
    serviceConfig = {
      WorkingDirectory = "/home/james/bookmarks_sync/archivebox";
      ExecStartPre = pkgs.tailscaleWaitOnline;
      ExecStart = "${pkgs.archivebox}/bin/archivebox server";
    };
  };

  # systemd.user.paths.archivebox-export-trigger = {
  #   Unit.Description = "Watch bookmarks.xbel for changes and trigger export";
  #   Path.PathChanged = "/home/james/bookmarks_sync/floccus_webdav/bookmarks.xbel";
  #   Install.WantedBy = [ "default.target" ];
  # };

  systemd.user.services.archivebox-import = {
    description = "Archivebox import service";
    environment = {
      DEBUG = "True";
      ONLY_NEW = "TRUE";
      SAVE_ARCHIVE_DOT_ORG = "False";
    };
    wantedBy = [
      "archivebox.service"
    ];
    after = [
      "archivebox.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      WorkingDirectory = "/home/james/bookmarks_sync/archivebox";
      ExecStartPre = "${pkgs.archivebox}/bin/archivebox add < ../floccus_webdav/bookmarks.xbel";
      ExecStart = "${pkgs.archivebox}/bin/archivebox update";
    };
  };
}
