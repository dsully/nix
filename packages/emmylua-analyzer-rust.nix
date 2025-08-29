{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "519a6a40060021743d6357f1b122b5c056b859f9";
    pname = "emmylua-analyzer-rust";
    version = "0.12.0-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "EmmyLuaLs";
      repo = "emmylua-analyzer-rust";
      hash = "sha256-DDPfH6k1iAGbQGGFwXW7G4GPaIq/mcmFpnDxjyqRWyY=";
    };

    cargoHash = "sha256-7QQipbnqelLdzQr+lIORyQNM9SS5yHaJLQ31M52lYCw=";
    doCheck = false;

    nativeBuildInputs = [
      pkg-config
    ];

    meta = {
      description = "";
      homepage = "https://github.com/EmmyLuaLs/emmylua-analyzer-rust/";
      changelog = "https://github.com/EmmyLuaLs/emmylua-analyzer-rust/blob/${src.rev}/CHANGELOG.md";
      license = lib.licenses.mit;
      mainProgram = "emmylua_ls";
    };
  }
