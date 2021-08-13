self: super:

let
  version = "4.28.0";
  feather-font = self.stdenv.mkDerivation {
    inherit version;
    pname = "feather-font";

    src = self.pkgs.fetchFromGitHub {
      name = "feather-font-${version}";

      owner = "adi1090x";
      repo = "polybar-themes";
      rev = "46154c5283861a6f0a440363d82c4febead3c818";

      sha256 = "w1EqvFvQH0+CqzuJRBxUJLnG5joQVFlcSxyw9TvW4VI=";
    };

    installPhase = ''
      mkdir -p $out/share/fonts/feather
      cp fonts/feather.ttf $out/share/fonts/feather
    '';

    # postFetch = ''
    #   mkdir -p $out/share/fonts
    #   ls -lah
    #   ${self.pkgs.file}/bin/file $downloadedFile
    #   unpackFile $downloadedFile
    #   ls -lah
    #   cp fonts/feather.ttf -d $out/share/fonts/feather
    # '';
  };
in
{
  inherit feather-font;
}
