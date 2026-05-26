{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "mcp-mux";
  version = "0.25.0";

  src = fetchFromGitHub {
    owner = "thebtf";
    repo = "mcp-mux";
    rev = "e176f3b2ba788be849bc06b405ae2e4171c49a4f";
    hash = "sha256-ICy0DM7davRkCw2HZkN86wKMT8JCwwMlc2ZXOgp3m0g=";
  };

  vendorHash = "sha256-U//pCwk+37fc3UkQYdAH1Ob6pI4eB+hBPABtJoeH6E8=";

  subPackages = ["cmd/mcp-mux"];

  ldflags = ["-s"];

  meta = {
    description = "Transparent stdio multiplexer for MCP servers — share one upstream across multiple Claude Code sessions";
    homepage = "https://github.com/thebtf/mcp-mux";
    license = lib.licenses.mit;
    mainProgram = pname;
  };
}
