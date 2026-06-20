{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "mcp-mux";
  version = "0.26.13";

  src = fetchFromGitHub {
    owner = "thebtf";
    repo = "mcp-mux";
    rev = "2320ec31e508008b25d4821be76523041f684aee";
    hash = "sha256-5I9I7mvlJgoZqu4eYEWKsOr3DVSRmf9A8ZUDx+2JC9g=";
  };

  vendorHash = "sha256-zYUQzX0IOcDvoA7kYkYneWzjCRQMwvfQPaJblUb3kLA=";

  subPackages = ["cmd/mcp-mux"];

  ldflags = ["-s"];

  meta = {
    description = "Transparent stdio multiplexer for MCP servers — share one upstream across multiple Claude Code sessions";
    homepage = "https://github.com/thebtf/mcp-mux";
    license = lib.licenses.mit;
    mainProgram = pname;
  };
}
