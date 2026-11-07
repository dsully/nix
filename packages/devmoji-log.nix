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
  version = "0.1.1";

  src = fetchFromGitHub {
    owner = "dsully";
    repo = pname;
    rev = "30292045e4e3bb8ebd75ae7fa800693c57b79380";
    hash = "sha256-5e9kxxMu3gJhMuSpkcm4bgplie7qWzSD1+MY0rEH4V8=";
  };

  cargoHash = "sha256-WJcljsZZFa7SNXUoAvyiK0yxgf/1QdE1X80BXvFeu7M=";
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
