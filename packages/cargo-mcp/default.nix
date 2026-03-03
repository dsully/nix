{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "cargo-mcp";
    version = "0.1.0";

    src = fetchFromGitHub {
      owner = "SignalWhisperer";
      repo = "cargo-mcp";
      rev = "3f032879a5bef3e217a9ed3c57b2169e860fa3d2";
      hash = "sha256-f89PF9fEJUi8lYlx45zAT6bgwGYPVe4luy3y2sTc6yg=";
    };

    cargoLock = {
      lockFile = ./Cargo.lock;
    };

    doCheck = false;

    postPatch = ''
      ln -s ${./Cargo.lock} Cargo.lock
    '';

    meta = {
      description = "Cargo MCP Server";
      homepage = "https://github.com/SignalWhisperer/cargo-mcp";
      mainProgram = pname;
    };
  }
