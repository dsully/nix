{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "mcp-mux";
  version = "0.26.8";

  src = fetchFromGitHub {
    owner = "thebtf";
    repo = "mcp-mux";
    rev = "08731ba1faaef13dd664a3e6ef133a463934fc49";
    hash = "sha256-RonBrps8WiqoV35IEcXczOx3X//wV7LN+21/nxLh0E4=";
  };

  vendorHash = "sha256-5+GgThQ14tTIlHwcMoo+fgIMzZx9xq5o3dTPW7MsFHQ=";

  subPackages = ["cmd/mcp-mux"];

  ldflags = ["-s"];

  meta = {
    description = "Transparent stdio multiplexer for MCP servers — share one upstream across multiple Claude Code sessions";
    homepage = "https://github.com/thebtf/mcp-mux";
    license = lib.licenses.mit;
    mainProgram = pname;
  };
}
