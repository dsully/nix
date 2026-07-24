{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "magic-opener";
  version = "0.3.5";
  rev = "ad096699a2a13e2cc2603322f14f189dd87adf34";

  src = fetchFromGitHub {
    inherit rev;
    owner = "dsully";
    repo = pname;
    hash = "sha256-a+jXHdjRPYHIcX8xVXT88u80Ztmop6QuhvABI+j13s8=";
  };

  cargoHash = "sha256-QF7YbsKXN4beX9tAq/82t4k7Gkx3Blo9AvIdtDQHMgg=";
  doCheck = false;

  meta = {
    description = "A tool for opening the right thing in the right place";
    homepage = "https://github.com/dsully/magic-opener";
    license = lib.licenses.mit;
    mainProgram = "open";
  };
}
