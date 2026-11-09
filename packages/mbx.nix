{
  lib,
  rustPlatform,
  fetchFromGitHub,
  cmake,
  makeWrapper,
}:
rustPlatform.buildRustPackage rec {
  pname = "mbx";
  version = "1.30.0";

  src = fetchFromGitHub {
    owner = "jdx";
    repo = "mr-boxington";
    rev = "2299ea69519d142d85b5903cbd0e2690419b7bed";
    hash = "sha256-Smz5HWY8LWuwsE6dyJ1bjURF8kDmt9AevdIa0NM+awo=";
  };

  cargoHash = "sha256-y6O6zdwqD0g5J5Z39pvnKLT8t/sr6N6fZG9n2K1RlrM=";
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
