{
  lib,
  rustPlatform,
  pkg-config,
  openssl,
  stdenv,
  src,
}:
rustPlatform.buildRustPackage rec {
  pname = "qbit-port-update";
  version = "0.0.1-${src.shortRev or "dev"}";

  inherit src;

  hash = "sha256-HpX6Icy/5sPYGZOUP0H/arV7ay6k/9LXQVGA2B3qWQE=";

  cargoHash = "sha256-DNijask9UcPSYXdLixKmFDqexsJuxhf2D4gZyfy8714=";
  doCheck = false;

  nativeBuildInputs = lib.optionals stdenv.isLinux [
    pkg-config
  ];

  buildInputs = lib.optionals stdenv.isLinux [
    openssl
  ];

  meta = {
    description = "QB Tools";
    homepage = "https://github.com/dsully/qbit-port-update.git";
    mainProgram = pname;
    platforms = lib.platforms.linux;
  };
}
