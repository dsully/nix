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
    rev = "2a971bb0e973875c37aea21fcf48a314d6d1db9f";
    hash = "sha256-1mdCy5aQ58BJxNKb5FeLOElale5pDi3Dr24zwwi7faE=";
  };

  cargoHash = "sha256-LWkjc8ohd6l4P1KmOQlJrFA9Q+tI5yD0/KaxguKFCRU=";
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
