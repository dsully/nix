{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "ccometixline";
    version = "664c6dbf";
    rev = "664c6dbf4075a8f03b5ba218b82921028c23f674";

    src = fetchFromGitHub {
      inherit rev;
      owner = "Haleclipse";
      repo = "CCometixLine";
      hash = "sha256-ygkUH3CAdlpL76f8/Q3vFC+lRc0bDlE8qSxXOUoAtEA=";
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
