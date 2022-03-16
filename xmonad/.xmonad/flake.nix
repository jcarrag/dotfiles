{
  outputs = { self, unstable }: {

    devShell.x86_64-linux =
      let
        system = "x86_64-linux";
        pkgs = import unstable {
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
