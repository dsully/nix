{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nix-update-script,
  python3,
}:
buildNpmPackage rec {
  pname = "quicken-mac-mcp";
  version = "0-561c0621";

  src = fetchFromGitHub {
    owner = "dsully";
    repo = "quicken-mac-mcp";
    rev = "561c06212a50010705308c6376c55c416e0d644f";
    hash = "sha256-cWm+jsJvIe00Edzrxgrj3ds9Wjm/dFULXyQt4VejiWI=";
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
