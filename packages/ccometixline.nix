{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "ccometixline";
    version = "e1192c72";
    rev = "e1192c7282c475744b0fc6221c10149f41667d80";

    src = fetchFromGitHub {
      inherit rev;
      owner = "Haleclipse";
      repo = "CCometixLine";
      hash = "sha256-afXdP8TSXBVb3J3eYqz+CIpomRNUza2jQtA96Wu6Rkk=";
    };

    cargoHash = "sha256-hWsxdl6qabU9x8oMW8f1sH6B2KHeU8ZNxm2wPUpERxc=";
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
