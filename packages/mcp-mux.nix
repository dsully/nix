{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "mcp-mux";
  version = "0.27.1";

  src = fetchFromGitHub {
    owner = "thebtf";
    repo = "mcp-mux";
    rev = "5f0ebb3c6c51cd6345b21bdf8ef0d0b21dc89338";
    hash = "sha256-+KD1/uUl+At0k0uw4VkMQ3HSPdn/Wo9u/ZjrBUPIZjc=";
  };

  vendorHash = "sha256-qFOaMXxhb4cGk2DQDTl5HrEnEuK4acur05eABOWYNBI=";

  subPackages = ["cmd/mcp-mux"];

  ldflags = ["-s"];

  meta = {
    description = "Transparent stdio multiplexer for MCP servers — share one upstream across multiple Claude Code sessions";
    homepage = "https://github.com/thebtf/mcp-mux";
    license = lib.licenses.mit;
    mainProgram = pname;
  };
}
