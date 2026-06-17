{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "mcp-mux";
  version = "0.26.7";

  src = fetchFromGitHub {
    owner = "thebtf";
    repo = "mcp-mux";
    rev = "41a2d6728b87950b39fa0ca1cb80329ac616b63a";
    hash = "sha256-aHG3+Mo/H9QMuX5eanBds9W2LiZaT3md/qwtotlUcJA=";
  };

  vendorHash = "sha256-FKLV7A2xTsOrG6nPdNr8tbSHaKLWhay+l3+WBpWb+YQ=";

  subPackages = ["cmd/mcp-mux"];

  ldflags = ["-s"];

  meta = {
    description = "Transparent stdio multiplexer for MCP servers — share one upstream across multiple Claude Code sessions";
    homepage = "https://github.com/thebtf/mcp-mux";
    license = lib.licenses.mit;
    mainProgram = pname;
  };
}
