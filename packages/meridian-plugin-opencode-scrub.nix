{
  buildNpmPackage,
  fetchFromGitHub,
  lib,
}:
buildNpmPackage {
  pname = "meridian-plugin-opencode-scrub";
  version = "0.2.0-8ace4ca1";

  src = fetchFromGitHub {
    owner = "rynfar";
    repo = "meridian-plugin-opencode-scrub";
    rev = "8ace4ca10551c168dc024355d782c4cef491aac5";
    hash = "sha256-LQLoffoy55ZMAeOcWCUZvjzWBpzO72bgVgqmbS1VFIk=";
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
