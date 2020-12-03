self: super:

{
  metals = super.metals.overrideAttrs (
    { pname, ... }:
      let
        version = "0.9.7+42-f6fec8c3-SNAPSHOT";
      in
        rec {
          inherit version;

          deps = super.stdenv.mkDerivation {
            name = "${pname}-deps-${version}";
            buildCommand = ''
              export COURSIER_CACHE=$(pwd)
              ${self.pkgs.coursier}/bin/coursier fetch org.scalameta:metals_2.12:${version} \
                -r bintray:scalacenter/releases \
                -r sonatype:snapshots > deps
              mkdir -p $out/share/java
              cp -n $(< deps) $out/share/java/
            '';
            outputHashMode = "recursive";
            outputHashAlgo = "sha256";
            # nix-hash --type sha256 --to-base32 $SHA256_HASH
            outputHash = "1xlbicjp4ahx2ahlcl2d9jrcp52g003xi24dl3d6gf7cz9zpqkp5";
          };

          buildInputs = [ self.jdk deps ];
        }
  );
}
