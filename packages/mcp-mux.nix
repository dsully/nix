{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "mcp-mux";
  version = "0.33.0";

  src = fetchFromGitHub {
    owner = "thebtf";
    repo = "mcp-mux";
    rev = "d9017877e29966c602b81bb939dc9bc610179981";
    hash = "sha256-92Q3ppXorURG7YqgEH8jpe+LfbEsFjVfbslvaq+50Bo=";
  };

  vendorHash = "sha256-DNjTkQm20tW89ImTc2QcLJWrdbhG71gjirHOk6u1ws4=";
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
