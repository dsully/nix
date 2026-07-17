{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "mcp-mux";
  version = "0.27.2";

  src = fetchFromGitHub {
    owner = "thebtf";
    repo = "mcp-mux";
    rev = "f5fbe8c53cadb01fd4c792d699ec4f07a224facf";
    hash = "sha256-H1nRKxBYiKg1oNJoCk2rWnB9zm2JXEZjDrvvaoEjKqU=";
  };

  vendorHash = "sha256-mSeCz8NCwpX3J5FRYVF14OtI0Yc6eQBYPC3k8d9EBYA=";

  subPackages = ["cmd/mcp-mux"];

  ldflags = ["-s"];

  meta = {
    description = "Transparent stdio multiplexer for MCP servers — share one upstream across multiple Claude Code sessions";
    homepage = "https://github.com/thebtf/mcp-mux";
    license = lib.licenses.mit;
    mainProgram = pname;
  };
}
