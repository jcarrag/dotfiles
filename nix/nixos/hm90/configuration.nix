# EliteMini HM90
{ ... }:

{
  imports = [
    ../../modules/emby-server.nix
  ];

  autoLogin = {
    enable = true;
    user = "james";
  };

  programs.emby-server.enable = true;
}
