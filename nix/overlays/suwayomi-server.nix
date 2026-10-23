self: super:

{
  # nixpkgs 26.05 ships 2.1.1867, which only speaks extension API 1.4. keiyoushi
  # dropped that in 2026 and now serves it nothing but "Outdated App" stubs; API 1.6
  # arrived in v2.3.2223.
  suwayomi-server_2-4 = self.checkOverlayObsolete super.suwayomi-server "2.4.2366" (
    super.suwayomi-server.overrideAttrs (old: rec {
      version = "2.4.2366";
      src = super.fetchurl {
        url = "https://github.com/Suwayomi/Suwayomi-Server/releases/download/v${version}/Suwayomi-Server-v${version}.jar";
        hash = "sha256-r5/rIK+dfr6eMHaebG68f8erHERziNQuAoCx2l/ge/0=";
      };
    })
  );
}
