{
  lib,
  rustPlatform,
  fetchFromGitHub,
  cmake,
  makeWrapper,
}:
rustPlatform.buildRustPackage rec {
  pname = "mbx";
  version = "1.29.1";

  src = fetchFromGitHub {
    owner = "jdx";
    repo = "mr-boxington";
    rev = "316e45f26aa8d1b484011671ff686e56fe710fe0";
    hash = "sha256-v7sn89HEumNy4Z/qKzS5sgl8LenryVkf68CJTQx4pqk=";
  };

  cargoHash = "sha256-JgwXuoMbW+OqRO9i5QHzs7CFsUV7txSjZrKiy54zEbQ=";
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
