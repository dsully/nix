{
  buildNpmPackage,
  lib,
}:
# A Pi release laid out as <agent dir>/install/releases/<version>, which octet-pi-compat loads for Pi's own provider streams.
buildNpmPackage {
  pname = "pi-release";
  version = "1.5.2";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [./package.json ./package-lock.json];
  };

  npmDepsHash = "sha256-fWBW3Lx/fxA10bq+JjVcxChawOA2OOOoMLPFpNoKwL8=";
  npmFlags = ["--ignore-scripts"];
  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r node_modules package.json $out/
    runHook postInstall
  '';

  meta = {
    description = "Pi coding agent release tree for octet-pi-compat's installed-Pi helpers";
    homepage = "https://www.npmjs.com/package/@earendil-works/pi-coding-agent";
    license = lib.licenses.mit;
  };
}
