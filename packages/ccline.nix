{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "ccline";
    version = "1.0.8";
    rev = "e826bef808af86496eda8840156c71e3ef8d0ca6";

    src = fetchFromGitHub {
      inherit rev;
      owner = "Haleclipse";
      repo = "CCometixLine";
      hash = "sha256-OcK0UZDHAJTQOVqBUZbI9g7Q/ChYJ5Ukc+hdDUi6tPM=";
    };

    cargoHash = "sha256-PMmyJhbeXgxncXZh/RV0uyuWl9TmCeJAICxWXn0uB0o=";
    doCheck = false;

    # buildInputs = lib.optionals stdenv.isDarwin [
    #   darwin.apple_sdk.frameworks.Security
    # ];

    meta = {
      description = "Claude Code statusline tool written in Rust";
      homepage = "https://github.com/Haleclipse/CCometixLine";
      changelog = "https://github.com/Haleclipse/CCometixLine/blob/${src.rev}/CHANGELOG.md";
      mainProgram = pname;
    };
  }
