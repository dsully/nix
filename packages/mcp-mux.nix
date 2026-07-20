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
    rev = "f13cee8f62027eaa375637f1fd4537e5ff102580";
    hash = "sha256-iy7im7DrZoiOSPJAhN719XXca2FNCRt/dHZlsDubPRc=";
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
