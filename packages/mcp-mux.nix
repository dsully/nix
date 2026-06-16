{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "mcp-mux";
  version = "0.26.2";

  src = fetchFromGitHub {
    owner = "thebtf";
    repo = "mcp-mux";
    rev = "3a4685d6a2454bdbe7bf1aa489e9600346008780";
    hash = "sha256-RCOfi4Jff0pB4qmP1jFzRQSE69nWZN8lzkii56tJsNQ=";
  };

  vendorHash = "sha256-YzV/xI0JjdXzE4rLxgZvecYtvevDdLnG+IdpRXsDPZ0=";

  subPackages = ["cmd/mcp-mux"];

  ldflags = ["-s"];

  meta = {
    description = "Transparent stdio multiplexer for MCP servers — share one upstream across multiple Claude Code sessions";
    homepage = "https://github.com/thebtf/mcp-mux";
    license = lib.licenses.mit;
    mainProgram = pname;
  };
}
