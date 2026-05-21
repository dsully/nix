{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "mcp-mux";
  version = "0.24.3";

  src = fetchFromGitHub {
    owner = "thebtf";
    repo = "mcp-mux";
    rev = "2e9c6c9060be1174f30a5e65d88111c5c0948f3a";
    hash = "sha256-Z4L97pvPoRlH1jcIv5qR1Ne8mlj2W/JuDj2y7ym+O1s=";
  };

  vendorHash = "sha256-S6ifJprNuX6+/wupyf6FVMZOsNL+8Mf322NO3/BabRw=";

  subPackages = ["cmd/mcp-mux"];

  ldflags = ["-s"];

  meta = {
    description = "Transparent stdio multiplexer for MCP servers — share one upstream across multiple Claude Code sessions";
    homepage = "https://github.com/thebtf/mcp-mux";
    license = lib.licenses.mit;
    mainProgram = pname;
  };
}
