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
    rev = "25d6ed35b6d6bbd74cf6d833c0ff05c7fc335375";
    hash = "sha256-2T9gBg4QkESbC7x1D+cZjomJYgoWDegdq9TQUH2GH+Y=";
  };

  cargoHash = "sha256-5oax/80vEC99uGpM0wEniNRtQ97ScFw+dYVbAW4MHwM=";
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
