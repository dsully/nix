{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "magic-opener";
  version = "0.3.4";
  rev = "dc4c7fe3cf1e6f09f870996473826801907f26b0";

  src = fetchFromGitHub {
    inherit rev;
    owner = "dsully";
    repo = pname;
    hash = "sha256-ZrMlUWSGR4dpXHMcdkQG9EL76VNqW3bTPOX6gnNwoWI=";
  };

  cargoHash = "sha256-D3jMK5VRwRhMp8OazzWuCzrErJgS9cCBPVFEH9h5pak=";

  meta = {
    description = "A tool for opening the right thing in the right place";
    homepage = "https://github.com/dsully/magic-opener";
    license = lib.licenses.mit;
    mainProgram = "open";
  };
}
