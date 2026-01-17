{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "rust-mcp-filesystem";
    version = "0.4.0";

    src = fetchFromGitHub {
      owner = "rust-mcp-stack";
      repo = "rust-mcp-filesystem";
      rev = "d374610bde0c870324f715d166a80df869d75d1b";
      hash = "sha256-GC72nFi0fI3GIj6X0BW+b4/sixi7ATszxjhkv8SiAkA=";
    };

    cargoHash = "sha256-5GSWZGC/ACUcwCWC7giRqS+yj2SA/dsZtedcmAGvVJs=";
    doCheck = false;

    meta = {
      description = "Blazing-fast, asynchronous MCP server for seamless filesystem operations";
      homepage = "https://github.com/rust-mcp-stack/rust-mcp-filesystem";
      changelog = "https://github.com/rust-mcp-stack/rust-mcp-filesystem/blob/${src.rev}/CHANGELOG.md";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
