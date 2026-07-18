{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "mcp-mux";
  version = "0.28.0";

  src = fetchFromGitHub {
    owner = "thebtf";
    repo = "mcp-mux";
    rev = "747374341187dce533d0feebf05e211420964532";
    hash = "sha256-tparTN7C8v+iJW81+o14SQP3AC8oPRyjRoxRnMGBTZo=";
  };

  vendorHash = "sha256-HOHzABSBJ5dYShx3P59bGPaXJWq2nIo2YqjmkU+M5tY=";

  subPackages = ["cmd/mcp-mux"];

  ldflags = ["-s"];

  meta = {
    description = "Transparent stdio multiplexer for MCP servers — share one upstream across multiple Claude Code sessions";
    homepage = "https://github.com/thebtf/mcp-mux";
    license = lib.licenses.mit;
    mainProgram = pname;
  };
}
