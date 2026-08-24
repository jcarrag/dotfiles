self: super:

with super.lib;
let
  overlays = [
    (self: super: {
      brave = super.brave.override {
        commandLineArgs = "--enable-wayland-ime --password-store=basic";
      };

      hyprland = super.hyprland.overrideAttrs (oldAttrs: {
        debug = true;
        separateDebugInfo = true;
      });

      checkOverlayObsolete =
        upstreamPkg: targetVersion: overlaidPkg:
        if builtins.compareVersions upstreamPkg.version targetVersion >= 0 then
          throw ''
            Overlay obsolete: Upstream ${
              upstreamPkg.pname or upstreamPkg.name
            } has been updated to ${upstreamPkg.version}.
            It is now >= your target version of ${targetVersion}. 
            You can safely remove this overlay!
          ''
        else
          overlaidPkg;
    })
  ]
  ++ map import [
    ./aoe2de.nix
    ./anki.nix
    ./asciichart.nix
    ./calibre-web.nix
    ./emby-server.nix
    ./immich-upload-google-takeout.nix
    ./feather-font/feather-font.nix
    ./ferdi.nix
    ./rscls.nix
    ./scripts.nix
    ./systemd-services.nix
    ./taffybar
    ./tmate.nix
    ./virtualbox.nix
    ./xmonad
  ];
in
foldr (x: y: composeExtensions x y) (self: super: { }) overlays self super
