self: super:

let
  mkEmbyServer =
    { lib
    , stdenv
    , fetchurl
    , autoPatchelfHook
    , dpkg
    , makeWrapper
    , lttng-ust_2_12
    }:

    let
      version = "4.8.0.37";
      name = "emby-${version}";
    in
    stdenv.mkDerivation
      {
        inherit name version;
        # "https://github.com/MediaBrowser/Emby.Releases/releases/download/4.8.0.37/emby-server-deb_4.8.0.37_amd64.deb";
        src = fetchurl {
          url = "https://github.com/MediaBrowser/Emby.Releases/releases/download/${version}/emby-server-deb_${version}_amd64.deb";
          sha256 = "sha256-FceKPjDkt78jV1PVWX/4iID/qp3QGqbGPQYc42BreP4=";
        };

        preBuild = ''
          addAutoPatchelfSearchPath ${lib.makeLibraryPath [ lttng-ust_2_12 ]}
        '';

        nativeBuildInputs = [
          autoPatchelfHook
          dpkg
        ];

        unpackPhase = "true";

        installPhase = ''
          mkdir -p $out/bin
          dpkg -x $src .
          cp -r ./opt/emby-server/* $out/
          sed -i "s|APP_DIR=\/opt\/emby-server|APP_DIR=$out|g" $out/bin/*
        '';
      };
in
{
  emby-server = self.callPackage mkEmbyServer { };
}
