{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nix-update-script,
  python3,
}:
buildNpmPackage rec {
  pname = "quicken-mac-mcp";
  version = "0-0d15c7b6";

  src = fetchFromGitHub {
    owner = "dsully";
    repo = "quicken-mac-mcp";
    rev = "0d15c7b6d97b8b679b3dee45ee96cd2d7eeb0205";
    hash = "sha256-CLA4/KwCqDlOY/+liwmLx4zIXcekNJUjUXJ12FJyPsk=";
  };

  npmDepsHash = "sha256-WXO9/6uCFr3bilBuk5Wh5EIQ3NidlFFLp4dwr/2xh9k=";
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
