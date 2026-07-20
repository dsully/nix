{
  fetchFromGitHub,
  lib,
  libgit2,
  nix-update-script,
  openssl,
  pkg-config,
  rustPlatform,
  zlib,
}:
rustPlatform.buildRustPackage rec {
  pname = "gs";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "jeanduplessis";
    repo = "gs";
    rev = "223240db690ba6619c0106c9d847f8a83a1d71c3";
    hash = "sha256-BMV9eF3FatY1mTTF8JpK7SA4y5urYy/vp1sRSzuB75w=";
  };

  cargoHash = "sha256-f0Bl9JU+VpASC9f2M777kioz28nLZiM9v7At0lUibhk=";
  doCheck = false;

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    libgit2
    openssl
    zlib
  ];

  passthru.updateScript = nix-update-script {};

  meta = {
    description = "A better git status command";
    homepage = "https://github.com/jeanduplessis/gs";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [dsully];
    mainProgram = pname;
  };
}
