self: super:

{
  ferdi = super.ferdi.overrideAttrs (
    old: rec {
      version = "5.6.0-nightly.11";
      src = self.fetchurl {
        url = "https://github.com/getferdi/nightlies/releases/download/v${version}/ferdi_${version}_amd64.deb";
        sha256 = "VLTsaCTdKn8NjV+pPdwTgxM8i/XMXpZqrWd6EnWbD1A=";
      };
    }
  );
}
