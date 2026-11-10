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
    rev = "89d948ff5744475b6d8558f30616142aa53008b1";
    hash = "sha256-zDLEhzPa/9DyF9Ic3its/bvo8ebvHzxQ0EXfx/qNets=";
  };

  cargoHash = "sha256-5oax/80vEC99uGpM0wEniNRtQ97ScFw+dYVbAW4MHwM=";
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
