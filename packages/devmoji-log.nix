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
  version = "0.1.2";

  src = fetchFromGitHub {
    owner = "dsully";
    repo = pname;
    rev = "d8955570ab57bb9b3a5150f9eb971da96db2efb6";
    hash = "sha256-oqv+K3Wz0zJzwmIx7QF0ewnM9Sxxr6mPmyAWmur9DAQ=";
  };

  cargoHash = "sha256-Sad2E3Na/XsnGCri/IIZhWEcPy20O0GKOlDiZRHu0Vw=";
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
