# EliteMini HM90
{ ... }:

{
  imports = [
    ../../modules/emby-server.nix
  ];

  programs.emby-server = {
    enable = true;
    user = "emby-server";
    group = "users";
    openFirewall = true;
  };

  autoLogin = {
    enable = true;
    user = "james";
  };
}
