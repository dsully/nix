{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "rust-mcp-filesystem";
    version = "0.4.1";

    src = fetchFromGitHub {
      owner = "rust-mcp-stack";
      repo = "rust-mcp-filesystem";
      rev = "aa9af19d7cefe2657ca7ae32893b88049eb1f85a";
      hash = "sha256-WA0Sbds0t38v7w28BAejX9Nj2pT3pXb+AR1DGBCRzJI=";
    };

    cargoHash = "sha256-iHPaspikFYl6LWbDxbrioY4HViLKdVoW6dxnUpgF53o=";
    doCheck = false;

    meta = {
      description = "Blazing-fast, asynchronous MCP server for seamless filesystem operations";
      homepage = "https://github.com/rust-mcp-stack/rust-mcp-filesystem";
      changelog = "https://github.com/rust-mcp-stack/rust-mcp-filesystem/blob/${src.rev}/CHANGELOG.md";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
