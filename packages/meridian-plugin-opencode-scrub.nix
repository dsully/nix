{
  buildNpmPackage,
  fetchFromGitHub,
  lib,
}:
buildNpmPackage {
  pname = "meridian-plugin-opencode-scrub";
  version = "0.2.0-f58fe939";

  src = fetchFromGitHub {
    owner = "rynfar";
    repo = "meridian-plugin-opencode-scrub";
    rev = "f58fe939b344bbc17b2ba1be34f686b9219792e6";
    hash = "sha256-30ybLSP0hvaGI1V7BonjqYxOfzEq1Gd+vsledd0A+D0=";
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
