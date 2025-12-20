{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "ccometixline";
    version = "77144e1e";
    rev = "77144e1ed28eac9859ada7cb6b448725459e8a52";

    src = fetchFromGitHub {
      inherit rev;
      owner = "Haleclipse";
      repo = "CCometixLine";
      hash = "sha256-qPm5Od3GHrdPkiUkXvDvc90zf9uK62oDwTvKIk+ZYxs=";
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
