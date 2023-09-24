# EliteMini HM90
{ pkgs }:

{
  imports = [
    ../../modules/emby-server.nix
  ];

  programs = {
    emby-server = {
      enable = true;
      user = "emby-server";
      group = "users";
      openFirewall = true;
    };
    ynab-updater = {
      enable = true;
      configDir = "/home/james/.config/ynab-updater/settings.toml";
    };
  };

  services = {
    tailscale = {
      enable = true;
      useRoutingFeatures = "server";
      package = pkgs.unstable.tailscale.overrideAttrs (old: {
        postInstall = old.postInstall + ''
          wrapProgram $out/bin/tailscale --add-flags "--advertise-exit-node"
        '';
      });
    };
    xserver.displayManager.autoLogin = {
      enable = true;
      user = "james";
    };
  };
}
