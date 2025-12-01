{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "f3c3364c5682fb9c64d227ae6dc602612824eec2";
    pname = "geil";
    version = "0.0.1-alpha.1-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "Nukesor";
      repo = pname;
      hash = "sha256-a6FwJmKDWB8X7FtK6tBxefkRMldBlJuhJgDZExlqkaM=";
    };

    cargoHash = "sha256-MkvR+gsNwf8q3A/QdL4+lfDBAtQl7b4jCwzxT5391XY=";
    doCheck = false;

    meta = {
      description = "Rocket: A tool to update your repositories and for keeping them clean";
      homepage = "https://github.com/Nukesor/geil";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
