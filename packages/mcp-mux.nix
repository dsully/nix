{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "mcp-mux";
  version = "0.24.1";

  src = fetchFromGitHub {
    owner = "thebtf";
    repo = "mcp-mux";
    rev = "a6ccfd185e909bb7c76519dc9432ed77e19d2dce";
    hash = "sha256-ubtPuA0ExG2KtAsUnGveBIuSW66cY8u6FKMNw5rFNJo=";
  };

  vendorHash = "sha256-o5l9w8nFrxubei6fhnz3T4fZqlDykPGbXn1wU+/V7xQ=";

  subPackages = ["cmd/mcp-mux"];

  ldflags = ["-s"];

  meta = {
    description = "Transparent stdio multiplexer for MCP servers — share one upstream across multiple Claude Code sessions";
    homepage = "https://github.com/thebtf/mcp-mux";
    license = lib.licenses.mit;
    mainProgram = pname;
  };
}
