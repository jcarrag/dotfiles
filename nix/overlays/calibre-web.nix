self: super:

{
  calibre-web_0-6-27 = self.checkOverlayObsolete super.calibre-web "0.6.27" (
    super.calibre-web.overridePythonAttrs (old: {
      version = "0.6.27";

      src = super.fetchFromGitHub {
        owner = "janeczku";
        repo = "calibre-web";
        rev = "0.6.27";
        hash = "sha256-ULUEQ35R+jI0nCrwYkTvmaUqpi1a/Sjvs5kWHYfTTWY=";
      };

      postPatch = ''
        mkdir -p src/calibreweb
        touch src/calibreweb/__init__.py
        mv cps.py src/calibreweb/__main__.py
        mv cps src/calibreweb

        substituteInPlace pyproject.toml \
          --replace-fail 'cps = "calibreweb.__main__:main"' 'calibre-web = "calibreweb.__main__:main"'
      '';

      dependencies =
        old.dependencies
        ++ (with super.python3Packages; [
          nh3
        ]);
    })
  );
}
