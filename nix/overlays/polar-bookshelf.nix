self: super:

{
  polar-bookshelf =
    super.polar-bookshelf.overrideAttrs (
      _: let
        version = "2.0.103";
      in
        {
          version = version;
          src = self.fetchurl {
            url = "https://github.com/burtonator/polar-bookshelf/releases/download/v${version}/polar-desktop-app-${version}-amd64.deb";
            hash = "sha256-jcq0hW698bAhVM3fLQQeKAnld33XLkHsGjS3QwUpciQ=";
          };
          installPhase = ''
            mkdir -p $out/share/polar-bookshelf
            mkdir -p $out/bin
            mkdir -p $out/lib

            mv opt/Polar/* $out/share/polar-bookshelf
            mv $out/share/polar-bookshelf/*.so $out/lib
            mv usr/share/* $out/share/
            ln -s $out/share/polar-bookshelf/polar-desktop-app $out/bin/polar-desktop-app
            substituteInPlace $out/share/applications/polar-desktop-app.desktop \
              --replace "/opt/Polar/polar-desktop-app" "$out/bin/polar-desktop-app"
          '';
        }
    );
}
