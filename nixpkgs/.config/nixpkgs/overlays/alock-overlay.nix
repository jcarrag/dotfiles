self: super:

{
  alock = super.alock.overrideDerivation (attrs: {
    configureFlags = attrs.configureFlags ++ [ "--with-dunst" ];
  });
}
