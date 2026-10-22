{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "mcp-mux";
  version = "0.32.0";

  src = fetchFromGitHub {
    owner = "thebtf";
    repo = "mcp-mux";
    rev = "fd14aa17d94826accd5feb7fd39e2b7dd89483f3";
    hash = "sha256-wBFdH7vxPpc6qCZ0Q/GDQK6VvfpQGFxciNeJcb/SH2I=";
  };

  vendorHash = "sha256-ypWzKnAF+J7rfcBhPpzReG1S/CjbFUa1GWmHkI0ffvs=";
  doCheck = false;

  subPackages = ["cmd/mcp-mux"];

  ldflags = ["-s"];

  meta = {
    description = "Transparent stdio multiplexer for MCP servers — share one upstream across multiple Claude Code sessions";
    homepage = "https://github.com/thebtf/mcp-mux";
    license = lib.licenses.mit;
    mainProgram = pname;
  };
}
