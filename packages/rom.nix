{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "rom";
  version = "0.2.0-unstable-2026-06-03";

  src = fetchFromGitHub {
    owner = "manic-systems";
    repo = "rom";
    rev = "84824f78ca346fc2252591aa21f649f4c89feaf9";
    hash = "sha256-/pv6/pAEtsKhPMg1/Z5v/FImbuj4xvpm4Ik0sK55t+Q=";
  };

  cargoHash = "sha256-FvBdpEgFv/WHrfe0U2oy4k7neCN7iOSmNJhNxWNI1Kc=";
  doCheck = false;

  meta = {
    description = "Pretty build graphs for your pretty Nix builds";
    homepage = "https://github.com/manic-systems/rom";
    license = lib.licenses.eupl12;
    mainProgram = pname;
  };
}
