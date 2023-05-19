self: super:

{
  # taffybar-my = self.haskellPackages.callCabal2nix "taffybar-my" ./. {};
  taffybar-my = self.haskellPackages.developPackage {
    root = ./.;
    overrides = _: _: {
      # ghc = self.unstable.haskellPackages.ghc_9_6_1;
      # ghc.haskellCompilerName = "ghc-9.6.1";
      # pinned to ghc94 because:
      # https://discourse.haskell.org/t/facing-mmap-4096-bytes-at-nil-cannot-allocate-memory-youre-not-alone/6259
      ghc = self.unstable.haskell.compiler.ghc94;
    };
  };
}
