{
  lib,
  rustPlatform,
  fetchFromGitHub,
  nix-update-script,
}:
rustPlatform.buildRustPackage rec {
  pname = "rexurrect";
  version = "0-unstable-2026-10-27";

  src = fetchFromGitHub {
    owner = "cemcatik";
    repo = "rexurrect";
    rev = "da2a462167bd376c02adab0524c234791f0c3559";
    hash = "sha256-X/JcWrsJudYoUdbAOscsoLt+sPqINfVZOKqbBFXmzRQ=";
  };

  cargoHash = "sha256-pYF6g5gmNONGmkOAZyieL/4Hn/WnTKQHat6XA/Wgs4A=";
  doCheck = false;

  passthru.updateScript = nix-update-script {};

  meta = {
    description = "Save Rex sessions and recreate them after the Rex server stops";
    homepage = "https://github.com/cemcatik/rexurrect";
    license = lib.licenses.mit;
    mainProgram = pname;
  };
}
