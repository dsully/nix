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
    rev = "8add551d2b115fde6d9d7081c8fa2f0afc88c61d";
    hash = "sha256-YjeV4GWZzZyL+S5vcXhg+rgWY7L0sbaSLHqTWrhgHdg=";
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
