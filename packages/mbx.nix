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
    rev = "5248965f61bfb414a3faae30e547bcef45ea9d44";
    hash = "sha256-82Sr5wxviQm21QonS5I/OyShjWXG+H1+XjDJiRfS1H4=";
  };

  cargoHash = "sha256-MAVmW8Ngo5szLaHw8M8HKfkgBMrphux/wfHAtbU0AOs=";
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
