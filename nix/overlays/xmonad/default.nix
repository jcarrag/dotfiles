self: super:

{
  xmonad-config = builtins.readFile "${self.pkgs._self}/nix/overlays/xmonad/xmonad.hs";
}
