{
  inputs.taffybar-overlay = {
    url = "/home/james/dotfiles/nix/flakes/overlays/taffybar.nix";
    flake = false;
  };
  outputs = { self, nixpkgs, taffybar-overlay }: {

    devShell.x86_64-linux =
      let
        system = "x86_64-linux";
        pkgs = import nixpkgs { overlays = [ (import taffybar-overlay.outPath) ]; system = system; };
      in
        with pkgs;
        mkShell {
          buildInputs = [
            (
              haskellPackages.ghcWithPackages
                (
                  hpkgs: with hpkgs; [
                    taffybar
                    xmonad-extras
                    xmonad-contrib
                    xmonad
                  ]
                )
            )
          ];
        };
  };
}
