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
  version = "0.1.3";

  src = fetchFromGitHub {
    owner = "dsully";
    repo = pname;
    rev = "2839c175f4b6958d7fbd2ec38c96460878b7f772";
    hash = "sha256-OF31JDsYGxOzsTDrmXpW11yg6Oc+UcN5hd13/tkcMKI=";
  };

  cargoHash = "sha256-DUMlEJ+OHz11ClaKZxlrphr8m1KzTQqtAjwz41W9/0A=";
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
