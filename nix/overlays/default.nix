self: super:

with super.lib;
let
  overlays = [
    (self: super: {
       brave = super.brave.override {
         commandLineArgs =
           "--enable-wayland-ime";
         };
       }
    )
  ] ++ map import [
    ./aoe2de.nix
    ./anki.nix
    ./asciichart.nix
    ./emby-server.nix
    ./feather-font/feather-font.nix
    ./ferdi.nix
    ./nix-npm-install.nix
    ./scripts.nix
    ./systemd-services.nix
    ./taffybar
    ./tmate.nix
    ./virtualbox.nix
    ./xmonad
  ];
in
foldr (x: y: composeExtensions x y) (self: super: { }) overlays self super
