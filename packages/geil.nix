{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  rev = "586743a62d8083e71816969f41917de4ee933ff9";
  pname = "geil";
  version = "0.0.1-alpha.1-${rev}";

  src = fetchFromGitHub {
    inherit rev;
    owner = "Nukesor";
    repo = pname;
    hash = "sha256-jdwZknyycvJ/8m+e9sI97oZ/WH6AVuxGxl/R315BqYM=";
  };

  cargoHash = "sha256-o0/ZPA98zGAJUxtdumAyUsd3+MbPzhZ5RlKSl22iBLs=";
  doCheck = false;

  meta = {
    description = "Rocket: A tool to update your repositories and for keeping them clean";
    homepage = "https://github.com/Nukesor/geil";
    license = lib.licenses.mit;
    mainProgram = pname;
  };
}
