{
  outputs = { self, nixpkgs }: {

    devShell.x86_64-linux =
      let
        system = "x86_64-linux";
        pkgs = import nixpkgs {
          system = system;
          config = {
            allowUnfree = true;
            allowBroken = true;
          };
        };
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
