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
  version = "1.31.0";

  src = fetchFromGitHub {
    owner = "jdx";
    repo = "mr-boxington";
    rev = "042ebcfa70b5db0b810fb4a9db1ffea1e27c3d10";
    hash = "sha256-jqlea4lgGw073ts3npUAWLTLFnsth9wkdBq9ZZwy1ZA=";
  };

  cargoHash = "sha256-mlb3MADreLDbDXPuyr1ep/KwZ4oJEcgShC6GZpQIYmg=";
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
