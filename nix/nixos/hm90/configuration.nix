# EliteMini HM90
{ ... }:

{
  imports = [
    ../../modules/emby-server.nix
  ];

  programs.emby-server.enable = true;
}
