{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  libgit2,
  openssl,
  zlib,
}:
rustPlatform.buildRustPackage rec {
  pname = "turbo-commit";
  rev = "885e23377fba3e3766c88075a31aee78089ea034";
  version = "3.0.0-${rev}";

  src = fetchFromGitHub {
    inherit rev;
    owner = "dikkadev";
    repo = "turboCommit";
    hash = "sha256-hmm0AhGvFrpcg3XKukVEghAm6AQVgQgzm2JIJyFPKsQ=";
  };

  cargoHash = "sha256-spHPpsGVvAN4yJYVLP8UDIxdPwMnzqzOLXncdJS7EOU=";
  doCheck = false;

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    libgit2
    openssl
    zlib
  ];

  meta = {
    description = "Turbocommit is a tool that generates high-quality git commit messages in accordance with the Conventional Commits specification";
    homepage = "https://github.com/dikkadev/turboCommit";
    license = lib.licenses.mit;
    mainProgram = "turbocommit";
  };
}
