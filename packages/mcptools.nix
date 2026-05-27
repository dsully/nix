{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
}:
buildGoModule rec {
  pname = "mcptools";
  rev = "e7bd7246118384095ba22fd219ff38a1bf1cb792";
  version = "0.7.1-${rev}";

  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "f";
    repo = "mcptools";
    inherit rev;
    hash = "sha256-B6R87Jbl/dDcEnoKeinZZcLMsT//e3xoOg67VVSeI68=";
  };

  vendorHash = "sha256-S+RAQSEYRwt3mjN3JqFFO91lAtdjv+7NdAiR2nxuDIc=";
  doCheck = false;

  # Upstream `web` sets DisableFlagParsing and only handles --port/--server-logs,
  # so --auth-header/--auth-user never reach the client. Mirror shell.go's parsing.
  postPatch = ''
    substituteInPlace cmd/mcptools/commands/web.go \
      --replace-fail \
        $'\t\t\t\tcase cmdArgs[i] == FlagServerLogs:\n\t\t\t\t\tShowServerLogs = true\n' \
        $'\t\t\t\tcase cmdArgs[i] == FlagServerLogs:\n\t\t\t\t\tShowServerLogs = true\n\t\t\t\tcase cmdArgs[i] == FlagAuthUser && i+1 < len(cmdArgs):\n\t\t\t\t\tAuthUser = cmdArgs[i+1]\n\t\t\t\t\ti++\n\t\t\t\tcase cmdArgs[i] == FlagAuthHeader && i+1 < len(cmdArgs):\n\t\t\t\t\tAuthHeader = cmdArgs[i+1]\n\t\t\t\t\ti++\n'
  '';

  ldflags = [
    "-s"
    "-w"
    "-X=main.Version=${version}"
  ];

  passthru.updateScript = nix-update-script {};

  meta = {
    description = "A command-line interface for interacting with MCP (Model Context Protocol) servers using both stdio and HTTP transport";
    homepage = "https://github.com/f/mcptools";
    license = lib.licenses.mit;
    mainProgram = "mcp";
  };
}
