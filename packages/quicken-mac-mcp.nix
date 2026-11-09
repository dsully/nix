{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nix-update-script,
  python3,
}:
buildNpmPackage rec {
  pname = "quicken-mac-mcp";
  version = "0-bcd37a25";

  src = fetchFromGitHub {
    owner = "dsully";
    repo = "quicken-mac-mcp";
    rev = "bcd37a252125f9f37e363edcfa8afcfd30015b8b";
    hash = "sha256-uMSuBJz5RYn5EYPdkuuZpgVvpTcUReFM5HfwBjFrm3A=";
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
