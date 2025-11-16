{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "mcp-rust-analyzer";
    version = "0.2.0";
    rev = "3e28ade2ebd7d64ccff84af3b43ddd76b2496017";

    src = fetchFromGitHub {
      inherit rev;
      owner = "pedrozoalencar";
      repo = "mcp-rust-analyzer";
      hash = "sha256-R+3vUZkJiUAUORKtgHnsSLohQ96s8EuRCljPlrmTHtQ=";
    };

    cargoHash = "sha256-ZB84wWQpUvOgl44USeeVmD4VXKwyPigBzMFkjAziabs=";
    doCheck = false;

    nativeBuildInputs = [
      pkg-config
    ];

    buildInputs = [
      openssl
    ];

    meta = {
      description = "MCP server for Rust language intelligence via rust-analyzer integration";
      homepage = "https://github.com/pedrozoalencar/mcp-rust-analyzer";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
