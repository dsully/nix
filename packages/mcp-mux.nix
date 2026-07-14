{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "mcp-mux";
  version = "0.27.0";

  src = fetchFromGitHub {
    owner = "thebtf";
    repo = "mcp-mux";
    rev = "0ecf52d621310c61fb16726edbf77786318d9639";
    hash = "sha256-3qiBrO/WE87vfmjKp7TL2CcUp+0rTEirPoKYSgx+/mM=";
  };

  vendorHash = "sha256-JP7xDJqIrOA4wSSYPASsjtea57r7Y3zmGDwHJXjE7W8=";

  subPackages = ["cmd/mcp-mux"];

  ldflags = ["-s"];

  meta = {
    description = "Transparent stdio multiplexer for MCP servers — share one upstream across multiple Claude Code sessions";
    homepage = "https://github.com/thebtf/mcp-mux";
    license = lib.licenses.mit;
    mainProgram = pname;
  };
}
