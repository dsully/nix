{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "aacecc77cc6c2bed557888fc2e535ae9869caf9d";
    pname = "emmylua-analyzer-rust";
    version = "0.12.0-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "EmmyLuaLs";
      repo = "emmylua-analyzer-rust";
      hash = "sha256-O9AK5GSdKco7EkhVbLIhJJKNswRdRTAPETZpX7IefSw=";
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
