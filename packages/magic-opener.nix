{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage {
    pname = "magic-opener";
    version = "0.1.2";

    src = fetchFromGitHub {
      owner = "dsully";
      repo = "magic-opener";
      rev = "3297ebf38a1ef55da7521ba3302e18b686fc055a";
      hash = "sha256-ESFl16+qm9GgiKqtNFRBPmvZDL7gTuYxHE9WfsH6qKg=";
    };

    cargoHash = "sha256-XcHySOZwbjo8J7Is05r4bDDSNOOe2HzmCWkvXURhaUY=";
    useFetchCargoVendor = true;

    meta = {
      description = "A tool for opening the right thing in the right place";
      homepage = "https://github.com/dsully/magic-opener";
      license = lib.licenses.mit;
      mainProgram = "open";
    };
  }
