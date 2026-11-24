{
  lib,
  buildNpmPackage,
  bun,
  fetchFromGitHub,
  nodejs,
  removeReferencesTo,
  makeWrapper,
  nix-update-script,
}:
buildNpmPackage rec {
  pname = "safari-mcp";
  version = "2.23.0-44bc707c";

  src = fetchFromGitHub {
    owner = "achiya-automation";
    repo = "safari-mcp";
    rev = "44bc707c949ad476801bf5e6d27c643eeb23f398";
    hash = "sha256-F9faHr32BGw/ea1Yu7+XtXi/D62CAhb7aMTWL9X5f7I=";
  };

  npmDepsHash = "sha256-z1X9W61/6xdLLSQb3ZafoSCspIzrL6/s5RGEiuEwWEo=";
  dontNpmBuild = true;
  npmFlags = ["--ignore-scripts"];
  nativeBuildInputs = [makeWrapper removeReferencesTo];

  # Runs under bun: drop npm's node shebangs to keep nodejs out of the closure.
  # Only node_modules: rewriting safari-helper loses its stable codesign identifier.
  dontPatchShebangs = true;
  postInstall = ''
    find $out/lib/node_modules/${pname}/node_modules -type f -exec remove-references-to -t ${nodejs} {} +
    makeWrapper ${lib.getExe bun} $out/bin/${pname} \
      --add-flags $out/lib/node_modules/${pname}/index.js
  '';

  passthru.updateScript = nix-update-script {};

  meta = {
    description = "Native Safari browser automation for AI agents.";
    homepage = "https://github.com/achiya-automation/safari-mcp";
    license = lib.licenses.mit;
    mainProgram = pname;
    platforms = lib.platforms.darwin;
  };
}
