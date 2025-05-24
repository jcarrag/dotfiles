self: super:

{
  rscls = self.pkgs.rustPlatform.buildRustPackage {
    pname = "rscls";

    version = "0.0.1";

    src = self.pkgs.fetchFromGitHub {
      owner = "MiSawa";
      repo = "rscls";
      rev = "HEAD";
      hash = "sha256-1j7YRpozmBKfQyACE1wQp7gRegYZye26m1tlUaOLvtE=";
    };

    cargoHash = "sha256-NsFIryontZWRVDfAVTCDr5deBhvMggRJiiWj5tAAiK0=";
  };
}
