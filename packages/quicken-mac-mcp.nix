{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nix-update-script,
  python3,
}:
buildNpmPackage rec {
  pname = "quicken-mac-mcp";
  version = "0-unstable-2026-10-25";

  src = fetchFromGitHub {
    owner = "dsully";
    repo = "quicken-mac-mcp";
    rev = "c19bd72f7704578f308d3461cf78b3ef88bd260d";
    hash = "sha256-ajD8e1CqSjySxmaGyJ9YG+KqqDynABGpcu3FIUwu9S0=";
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
