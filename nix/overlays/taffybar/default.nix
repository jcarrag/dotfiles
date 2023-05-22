self: super:

{
  taffybar-my = self.unstable.haskellPackages.developPackage {
    root = ./.;
  };
}
