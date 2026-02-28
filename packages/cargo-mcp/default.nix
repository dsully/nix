{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "cargo-mcp";
    version = "0.1.0";

    src = fetchFromGitHub {
      owner = "SignalWhisperer";
      repo = "cargo-mcp";
      rev = "01f8748461f1b62be87ee41f81f97d69c503de88";
      hash = "sha256-9TEnlR4SxcVz3yOcL0Jk5YnFd5n15E9b3E8mFQLkkz4=";
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
