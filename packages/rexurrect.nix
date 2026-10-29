{
  lib,
  rustPlatform,
  fetchFromGitHub,
  nix-update-script,
}:
rustPlatform.buildRustPackage rec {
  pname = "rexurrect";
  version = "0.2.1";

  src = fetchFromGitHub {
    owner = "cemcatik";
    repo = "rexurrect";
    rev = "5fbe289c505846989ef103e993fbceb1d3b5af90";
    hash = "sha256-E/v//o1ytxGwsRVXzAiOy3x1ecihAQhGmuBuwTbM2no=";
  };

  cargoHash = "sha256-tjAbGFLkQLWUhUPREfsDrz331qc5kd3cXjb3WQT7Iq8=";
  doCheck = false;

  passthru.updateScript = nix-update-script {};

  meta = {
    description = "Save Rex sessions and recreate them after the Rex server stops";
    homepage = "https://github.com/cemcatik/rexurrect";
    license = lib.licenses.mit;
    mainProgram = pname;
  };
}
