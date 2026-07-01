{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  rev = "6e375374338be3f27f0a2e3995abcc41a3b0ae75";
  pname = "geil";
  version = "0.0.1-alpha.1-${rev}";

  src = fetchFromGitHub {
    inherit rev;
    owner = "Nukesor";
    repo = pname;
    hash = "sha256-1lqk+/3kSMMYvz55d9W5fMPeWPHavPyz2EnbiCBywjA=";
  };

  cargoHash = "sha256-/Ei+Mfyla5tKuAWhDgyoEZOPHp1tN5ry3GlZLHh0aVE=";
  doCheck = false;

  meta = {
    description = "Rocket: A tool to update your repositories and for keeping them clean";
    homepage = "https://github.com/Nukesor/geil";
    license = lib.licenses.mit;
    mainProgram = pname;
  };
}
