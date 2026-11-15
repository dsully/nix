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
  version = "2.23.0-7a13dd23";

  src = fetchFromGitHub {
    owner = "achiya-automation";
    repo = "safari-mcp";
    rev = "7a13dd2343d6377be6588728c954454e3f2cf3db";
    hash = "sha256-7D1FtfB1hNQj+cIPC4Pz+5+CPQTHauF340bVzP7/zc8=";
  };

  npmDepsHash = "sha256-x1MpgtHgzQ182eBJKqN+0vmPclW492nmo4kZ+8+l2f8=";
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
