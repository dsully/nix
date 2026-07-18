{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "mcp-mux";
  version = "0.28.0";

  src = fetchFromGitHub {
    owner = "thebtf";
    repo = "mcp-mux";
    rev = "1b91f54c1d517db352136c7d16949a2662c52b0e";
    hash = "sha256-E0UhlxdcTuxI/hQ9xrwxnwMD2dZq1SKbuuBMWtgcL08=";
  };

  vendorHash = "sha256-2L9JnDDkPw5U0hd4suLZF+KOz7HDB1VcMbgiu+tMJbU=";

  subPackages = ["cmd/mcp-mux"];

  ldflags = ["-s"];

  meta = {
    description = "Transparent stdio multiplexer for MCP servers — share one upstream across multiple Claude Code sessions";
    homepage = "https://github.com/thebtf/mcp-mux";
    license = lib.licenses.mit;
    mainProgram = pname;
  };
}
