# EliteMini HM90
{ pkgs, config, ... }:

{
  imports = [
    ../../modules/emby-server.nix
    ../../modules/tailscale-funnel.nix
  ];

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
  };

  programs = {
    emby-server = {
      enable = true;
      user = "emby-server";
      group = "users";
      openFirewall = true;
    };
    ynab-updater = {
      enable = true;
      configDir = "/home/james/.config/ynab-updater";
    };
    tailscale-funnel.services = {
      calibre-web = {
        enable = true;
        port = config.services.calibre-web.listen.port;
        path = "/";
      };
    };
  };

  services = {
    calibre-web = {
      enable = true;
      listen.ip = "0.0.0.0";
      options = {
        enableBookUploading = true;
        calibreLibrary = "/home/james/Calibre Library";
      };
      user = "james";
      group = "users";
    };
    tailscale = {
      enable = true;
      package = pkgs.unstable.tailscale;
      useRoutingFeatures = "server";
      extraUpFlags = [
        "--advertise-exit-node"
      ];
    };
    xserver.displayManager.autoLogin = {
      enable = true;
      user = "james";
    };
  };
}
