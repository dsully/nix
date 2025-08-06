{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "magic-opener";
    version = "0.3.0";

    src = fetchFromGitHub {
      owner = "dsully";
      repo = pname;
      rev = "1eb0cbd927a7e672a4fc1b06e5fbf37a32419547";
      hash = "sha256-G8otNSn02UcncuOxlszWDx9h/X9hY5Z4EbxI9s0P0rk=";
    };

    cargoHash = "sha256-PnUL4+l1L5yO1z9wL6Gp+KtFYYdh8k/4fRWr2zEscC8=";

    meta = {
      description = "A tool for opening the right thing in the right place";
      homepage = "https://github.com/dsully/magic-opener";
      license = lib.licenses.mit;
      mainProgram = "open";
    };
  }
