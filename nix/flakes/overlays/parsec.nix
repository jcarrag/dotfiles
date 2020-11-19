self: super:

{
  parsec = with self; stdenv.mkDerivation rec {
    pname = "parsec";
    version = "1.0.0";

    src = fetchurl {
      url = "https://builds.parsecgaming.com/package/parsec-linux.deb";
      sha256 = "DHIH9Bk3f8NeMESKzQDYcBMArFpEk2rG2HpGjJr8zcE=";
    };

    buildInputs = [ dpkg ];

    sourceRoot = ".";

    nativeBuildInputs = [ makeWrapper ];

    unpackCmd = ''
      dpkg -x "$src" .
    '';

    installPhase = ''
      mv usr/* ./
      rm -r usr/
      mkdir -p usr/bin/
      mv bin/parsecd usr/bin/parsecd-unwrapped
      makeWrapper ${steam-run}/bin/steam-run bin/parsecd --add-flags "$out/usr/bin/parsecd-unwrapped app_daemon=1"
      cp -r ./ $out/
    '';
  };
}
