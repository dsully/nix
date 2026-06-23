{
  buildNpmPackage,
  lib,
  src,
}:
buildNpmPackage rec {
  pname = "meridian-plugin-opencode-scrub";
  version = "0.2.0";

  inherit src;

  npmDepsHash = "sha256-Djxj21TH6FTZxwS9rY2vuYhJDpo2BvRCJ4N6nauDH9Q=";

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -R dist $out/dist

    runHook postInstall
  '';

  meta = {
    description = "Meridian plugin that strips OpenCode identifying fingerprints from the system prompt";
    homepage = "https://github.com/rynfar/meridian-plugin-opencode-scrub";
    license = lib.licenses.mit;
  };
}
