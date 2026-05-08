{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule (finalAttrs: rec {
  pname = "mcp-mux";
  version = "0.24.1";

  src = fetchFromGitHub {
    owner = "thebtf";
    repo = "mcp-mux";
    tag = "v${finalAttrs.version}";
    hash = "sha256-TdjcnoO5WNAI1tVbo9Wk7b1RJff+JktCGPL0xyqalnQ=";
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
})
