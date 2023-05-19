self: super:

{
  taffybar-my = self.haskellPackages.developPackage {
    root = ./.;
    overrides = _: _super: {
      # pinned to ghc94 because:
      # https://discourse.haskell.org/t/facing-mmap-4096-bytes-at-nil-cannot-allocate-memory-youre-not-alone/6259
      ghc = self.unstable.haskell.compiler.ghc94;
      iproute = self.haskell.lib.dontCheck _super.iproute;
    };
    source-overrides = {
      xml-conduit = "1.9.0.0";
    };
  };
}
