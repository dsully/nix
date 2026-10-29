{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nix-update-script,
  python3,
}:
buildNpmPackage rec {
  pname = "quicken-mac-mcp";
  version = "0-119e2724";

  src = fetchFromGitHub {
    owner = "dsully";
    repo = "quicken-mac-mcp";
    rev = "119e2724a3cb0eab8729147d70b0d25f49326f2c";
    hash = "sha256-OW3eCI43/DErmngdvPirg0IB5au48Judw3HxViQBQBQ=";
  };

  npmDepsHash = "sha256-5MxeO6gq6jkx/vblvPCF0m38Zgmuh86vLr0BdwnoI3U=";
  doCheck = false;

  nativeBuildInputs = [python3];
  passthru.updateScript = nix-update-script {extraArgs = ["--version=branch=writes"];};

  meta = {
    description = "MCP server providing read-only access to Quicken For Mac financial data via Claude";
    homepage = "https://github.com/dweekly/quicken-mac-mcp";
    license = lib.licenses.mit;
    mainProgram = pname;
    platforms = lib.platforms.darwin;
  };
}
