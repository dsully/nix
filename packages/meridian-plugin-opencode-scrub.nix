{
  buildNpmPackage,
  fetchFromGitHub,
  lib,
}:
buildNpmPackage {
  pname = "meridian-plugin-opencode-scrub";
  version = "0.2.0-0e491243";

  src = fetchFromGitHub {
    owner = "rynfar";
    repo = "meridian-plugin-opencode-scrub";
    rev = "0e491243924785995a9ed9e7f5044fb910aa374f";
    hash = "sha256-DhvhWaCCFrXcEwBzt6Y9lrqU97s1Wb5KR4VbQMz6H4c=";
  };

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
