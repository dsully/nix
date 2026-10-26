{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "mcp-mux";
  version = "0.33.3";

  src = fetchFromGitHub {
    owner = "thebtf";
    repo = "mcp-mux";
    rev = "094bc5655fcffb2a2558651824da2ac58fe12927";
    hash = "sha256-HPf6tqbLbjZhF7bgg43QV9KWvxfykG0x2Ab7SaK1fDs=";
  };

  vendorHash = "sha256-282qTvR6quBwQgQMKMg9jlBhds4biX6k45aXHDEUedE=";
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
