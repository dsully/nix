{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "mcp-mux";
  version = "0.29.1";

  src = fetchFromGitHub {
    owner = "thebtf";
    repo = "mcp-mux";
    rev = "cee544497feede0df1d5f8dcc8d2d99b59770b5f";
    hash = "sha256-FIAq7ibRfQ2cnTNLLyLbOjy/eciXrnlpx6jwnB3zQTg=";
  };

  vendorHash = "sha256-PrMbpUqk0x0gdiZXDa3vz/GK8Wce/vXZDEryktTblQg=";

  subPackages = ["cmd/mcp-mux"];

  ldflags = ["-s"];

  meta = {
    description = "Transparent stdio multiplexer for MCP servers — share one upstream across multiple Claude Code sessions";
    homepage = "https://github.com/thebtf/mcp-mux";
    license = lib.licenses.mit;
    mainProgram = pname;
  };
}
