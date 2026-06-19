{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "mcp-mux";
  version = "0.26.11";

  src = fetchFromGitHub {
    owner = "thebtf";
    repo = "mcp-mux";
    rev = "5db8b70a4260e9497af6417fcf51d6eef606e1b9";
    hash = "sha256-gX9LYAhd9Io17ynKgZv7J9KPdnbzIKvZkUo1niF9gmo=";
  };

  vendorHash = "sha256-PZyIg4+xDheoUFXEF4n/9dAUkdxqtimkW98Fd2Jq4Og=";

  subPackages = ["cmd/mcp-mux"];

  ldflags = ["-s"];

  meta = {
    description = "Transparent stdio multiplexer for MCP servers — share one upstream across multiple Claude Code sessions";
    homepage = "https://github.com/thebtf/mcp-mux";
    license = lib.licenses.mit;
    mainProgram = pname;
  };
}
