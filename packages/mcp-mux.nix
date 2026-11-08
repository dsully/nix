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
    rev = "0f021a8c8ed3f75ce6b18366dd2468783fe0bf4c";
    hash = "sha256-96ZMjYx+yC4G9wXpt8BVZfj4cf0VQ469PhHP9aPvp3c=";
  };

  # Upstream thebtf/mcp-mux#151 (open): daemon deadlocks when owners join new cwds during a spawn.
  patches = [./mcp-mux-add-cwd-outside-maintenance-gate.patch];

  vendorHash = "sha256-lKcwwhQ+E5h/tSAGu5lBvamA6cPuaj1Bn3wT+frcW5U=";
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
