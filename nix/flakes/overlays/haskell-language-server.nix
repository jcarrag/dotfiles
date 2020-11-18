self: super:

{
  haskell-language-server =
    with super.haskell.lib;
    let
      hls-src = super.fetchFromGitHub {
        owner = "haskell";
        repo = "haskell-language-server";
        rev = "372a12e797069dc3ac4fa33dcaabe3b992999d7c";
        sha256 = "AYeFitkJOcs2PACc1me9p8j+lJ3rlGsVdS/v16EGV9w=";
      };
      all-cabal-hashes = self.pkgs.fetchurl {
        url = "https://github.com/commercialhaskell/all-cabal-hashes/archive/27a6d797fe4bf4f3694984c560f771b993bd2678.tar.gz";
        sha256 = "PP75s7DrBoZGTVPeQorxHNMfQlqMo4V0gI6l1wU7A7o=";
      };
      hp = (super.haskellPackages.override { inherit all-cabal-hashes; }).extend (
        super.lib.composeExtensions
          (
            super.haskell.lib.packageSourceOverrides {
              ghcide = "0.5.0";
              hie-compat = "0.1.0.0";
              lsp-test = "0.11.0.6";
              hie-bios = "0.7.1";
              implicit-hie-cradle = "0.2.0.1";
              ghc-lib = "8.10.2.20200916";
              ghc-lib-parser = "8.10.2.20200916";
              refinery = "0.3.0.0";
              hlint = "3.2";
              stylish-haskell = "0.12.2.0";
              fourmolu = "0.2.0.0";
              hls-plugin-api = "0.5.0.0";
            }
          )
          (
            hself: hsuper: {
              lsp-test = dontCheck hsuper.lsp-test;
              hie-bios = dontCheck hsuper.hie-bios;
              ghcide = dontCheck hsuper.ghcide;
              aeson = hsuper.aeson_1_5_2_0;
              brittany = hsuper.brittany.override {
                aeson = hsuper.aeson;
              };
              hls-tactics-plugin = hp.callCabal2nix "hls-tactics-plugin" (hls-src + "/plugins/tactics") {};
              hls-hlint-plugin = hp.callCabal2nix "hls-hlint-plugin" (hls-src + "/plugins/hls-hlint-plugin") {};
            }
          )
      );
    in
      dontCheck (hp.callCabal2nix "haskell-language-server" hls-src {});
}
