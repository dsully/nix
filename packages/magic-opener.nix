{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "magic-opener";
    rev = "297b17b35305618ebfeb0a5ea04bdb7d3617070b";
    version = "297b17b3";

    src = fetchFromGitHub {
      inherit rev;
      owner = "dsully";
      repo = pname;
      hash = "sha256-5gUm9Se5rjzXYMfIjKSZ6L/Vz9yJ1Qbnvr8lHdNA/jU=";
    };

    cargoHash = "sha256-BPxPxgwLVey4UJ8gBHSwrE9lKSsPojYQBKYLluCvqSQ=";

    meta = {
      description = "A tool for opening the right thing in the right place";
      homepage = "https://github.com/dsully/magic-opener";
      license = lib.licenses.mit;
      mainProgram = "open";
    };
  }
