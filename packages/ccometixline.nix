{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "ccometixline";
    version = "1.1.0";
    rev = "f36d76ac675b775e43c5f57dff02e1010654f31d";

    src = fetchFromGitHub {
      inherit rev;
      owner = "Haleclipse";
      repo = "CCometixLine";
      hash = "sha256-cdh5lwZnwBvdanAOsBLsTJxdyDP4+42cwcJr+VhIj20=";
    };

    cargoHash = "sha256-EojY4nLGtUUrx3J3ugMOMpYvrALBpJ15SbB4DNtE1Kc=";
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
