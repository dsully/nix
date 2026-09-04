{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "mcp-mux";
  version = "0.30.0";

  src = fetchFromGitHub {
    owner = "thebtf";
    repo = "mcp-mux";
    rev = "3881f27b931f6b9d0467c0a15dd4e1824969e125";
    hash = "sha256-vOjChRol1ogqaWG8JrKMMrYDCmZcOW8jdEH10Kdc96g=";
  };

  vendorHash = "sha256-hOLpUsTCCfMCl1jbC4po0VGW++rVq8H/ka1WVKWF0Gk=";

  subPackages = ["cmd/mcp-mux"];

  ldflags = ["-s"];

  meta = {
    description = "Transparent stdio multiplexer for MCP servers — share one upstream across multiple Claude Code sessions";
    homepage = "https://github.com/thebtf/mcp-mux";
    license = lib.licenses.mit;
    mainProgram = pname;
  };
}
