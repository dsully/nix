{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "rime";
    version = "0.3.0";
    rev = "2dfcf5e7a80052a1237c7d305aae9444c96b0387";

    src = fetchFromGitHub {
      inherit rev;
      owner = "lukasl-dev";
      repo = "rime";
      hash = "sha256-FLzYIYnzaMhxYXhQpJ5jl9T+vnkux099jc5qk+djbAU=";
    };

    cargoHash = "sha256-o1SF37ItSLcQaM7hvGT6Adh/ti8z3nyrbdESomnUEQU=";
    doCheck = false;

    meta = {
      description = "An MCP server for NixOS users";
      homepage = "https://github.com/lukasl-dev/rime";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
