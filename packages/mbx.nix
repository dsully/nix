{
  lib,
  rustPlatform,
  fetchFromGitHub,
  cmake,
  makeWrapper,
}:
rustPlatform.buildRustPackage rec {
  pname = "mbx";
  version = "1.29.2";

  src = fetchFromGitHub {
    owner = "jdx";
    repo = "mr-boxington";
    rev = "ffbf5a6969327ab58731f8613af711ba03c6dc2b";
    hash = "sha256-Ny1kMPmEupChFM/2v+VIIbwJiujdYvDULyvAUEV4HrQ=";
  };

  cargoHash = "sha256-VoRYa18UIy/MpdN52vLEIHWZYPQ6DlXTCRrd6vP+eu8=";
  cargoBuildFlags = ["--package" pname];
  doCheck = false;

  nativeBuildInputs = [cmake makeWrapper];
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
