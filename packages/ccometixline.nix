{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "ccometixline";
    version = "1.0.9";
    rev = "f10d9a682b1354104553c4cdaeda25b5700d4360";

    src = fetchFromGitHub {
      inherit rev;
      owner = "Haleclipse";
      repo = "CCometixLine";
      hash = "sha256-so/I8+3E1EkLFebIH+0OJeYQRIa9WLFOVhQNEP7IIEw=";
    };

    cargoHash = "sha256-4xGyrWnxKE4++Dj3CqPnqfH5uZrXKT0/rwEgshpO3jw=";
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
