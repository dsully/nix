{
  aws-lc,
  lib,
  rustPlatform,
  fetchFromGitHub,
  cmake,
  makeWrapper,
  openssl,
  pkg-config,
  zstd,
}:
rustPlatform.buildRustPackage rec {
  pname = "mbx";
  version = "1.30.0";

  src = fetchFromGitHub {
    owner = "jdx";
    repo = "mr-boxington";
    rev = "19c6491181b1941bb0e90ac39bd6e8269f014384";
    hash = "sha256-nnEnbPL5mvlzgGkwmfEtMUegQQQ/96DYTbn65gURR1k=";
  };

  cargoHash = "sha256-H8ylM5YFqi/+vGhfY4aIDoVNkljn6NOHXUm0s4ka9fk=";
  cargoBuildFlags = ["--package" pname];
  doCheck = false;

  nativeBuildInputs = [
    cmake
    makeWrapper
    pkg-config
  ];

  buildInputs = [
    aws-lc
    openssl
    zstd
  ];

  dontUseCmakeConfigure = true;

  # Same shim upstream's flake builds; kept out of bin/ so installing mbx alone doesn't take over cargo.
  postInstall = ''
    makeWrapper "$out/bin/mbx" "$out/libexec/mbx/cargo" \
      --set MBX_CARGO_SHIM_MODE 1 \
      --set MBX_CARGO_SHIM_PATH "$out/libexec/mbx/cargo"
  '';

  meta = {
    description = "A shared build cache for Rust projects";
    homepage = "https://github.com/jdx/mr-boxington";
    license = lib.licenses.mit;
    mainProgram = pname;
  };
}
