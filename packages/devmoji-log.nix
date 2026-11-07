{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  libgit2,
  zlib,
}:
rustPlatform.buildRustPackage rec {
  pname = "devmoji-log";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "dsully";
    repo = pname;
    rev = "bcecf438ac4385277a848a6705a57f3577032035";
    hash = "sha256-mZDaPODTNuxEF06PbU9uLHDfG3wduwpBiRIjeyrXuqY=";
  };

  cargoHash = "sha256-/e31PBajTOCmfw4byzpguC4ThrQdOeV6x+bA/bMb7fE=";
  doCheck = false;

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    libgit2
    zlib
  ];

  meta = {
    description = "Display Git commit history with conventional commit types and gitmojis";
    homepage = "https://github.com/dsully/devmoji-log";
    license = lib.licenses.mit;
    maintainers = ["dsully"];
    mainProgram = pname;
  };
}
