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
  version = "2.23.0-cc9a0821";

  src = fetchFromGitHub {
    owner = "achiya-automation";
    repo = "safari-mcp";
    tag = "v${version}";
    hash = "sha256-1ZilAyOxuoNADXYTNRD/8vfgd7ItExlHTDDS4SdbvbA=";
  };

  npmDepsHash = "sha256-l40gzW0kuiZM3saAUlb3AHkhgcu2027fJcwSAaifK7A=";
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
