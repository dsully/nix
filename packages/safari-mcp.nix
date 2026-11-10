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
  version = "2.23.0-813fd503";

  src = fetchFromGitHub {
    owner = "achiya-automation";
    repo = "safari-mcp";
    rev = "813fd503c566372f66bcb9edfa155238a80693cb";
    hash = "sha256-D2kJf3oCODJtpkijGQjCZyreMiwRYekIVK/6rKoUH50=";
  };

  npmDepsHash = "sha256-DQWzetO9iXXD2/jUwUE6hRVPd6YTjtoS1gg75ID/TH8=";
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
