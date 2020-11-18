self: super:

{
  # taffybar overlay https://github.com/NixOS/nixpkgs/issues/63500#issuecomment-692218882
  haskellPackages = with self.haskell.lib; super.haskellPackages.extend (
    hself: hsuper: let
      gi-cairo-render-src = self.fetchFromGitHub {
        owner = "cohomology";
        repo = "gi-cairo-render";
        rev = "051de28ff092e0be0dc28612c6acb715a8bca846";
        sha256 = "1v9kdycc91hh5s41n2i1dw2x6lxp9s1lnnb3qj6vy107qv8i4p6s";
      };
    in
      {
        gi-cairo-render = markUnbroken (
          overrideCabal (hsuper.gi-cairo-render)
            (
              drv: {
                src = gi-cairo-render-src;
                editedCabalFile = null;
                postUnpack = ''
                  mv source all
                  mv all/gi-cairo-render source
                '';
              }
            )
        );
        gi-cairo-connector = markUnbroken
          (
            overrideCabal (hsuper.gi-cairo-connector) (
              drv: {
                src = gi-cairo-render-src;
                editedCabalFile = null;
                postUnpack = ''
                  mv source all
                  mv all/gi-cairo-connector source
                '';
              }
            )
          );
        gi-dbusmenu = markUnbroken (hself.gi-dbusmenu_0_4_8);
        gi-dbusmenugtk3 = markUnbroken (hself.gi-dbusmenugtk3_0_4_9);
        gi-gdk = hself.gi-gdk_3_0_23;
        gi-gdkx11 = markUnbroken (
          overrideSrc hsuper.gi-gdkx11 {
            src = self.fetchurl {
              url = "https://hackage.haskell.org/package/gi-gdkx11-3.0.10/gi-gdkx11-3.0.10.tar.gz";
              sha256 = "0kfn4l5jqhllz514zw5cxf7181ybb5c11r680nwhr99b97yy0q9f";
            };
            version = "3.0.10";
          }
        );
        gi-gtk-hs = markUnbroken (hself.gi-gtk-hs_0_3_9);
        gi-xlib = markUnbroken (hself.gi-xlib_2_0_9);
        taffybar = markUnbroken (
          appendPatch hsuper.taffybar (
            self.fetchpatch {
              url = "https://github.com/taffybar/taffybar/pull/494/commits/a7443324a549617f04d49c6dfeaf53f945dc2b98.patch";
              sha256 = "0prskimfpapgncwc8si51lf0zxkkdghn33y3ysjky9a82dsbhcqi";
            }
          )
        );
        gtk-sni-tray = markUnbroken (hsuper.gtk-sni-tray);
        gtk-strut = markUnbroken (hsuper.gtk-strut);
      }
  );
}
