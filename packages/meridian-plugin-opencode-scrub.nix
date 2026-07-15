{
  buildNpmPackage,
  fetchFromGitHub,
  lib,
}:
buildNpmPackage {
  pname = "meridian-plugin-opencode-scrub";
  version = "0.2.0-59a1bfce";

  src = fetchFromGitHub {
    owner = "rynfar";
    repo = "meridian-plugin-opencode-scrub";
    rev = "59a1bfce767d1994a4bb6a700373e4c11aef3633";
    hash = "sha256-OhIYu4aZP+6RvlnDxraXfbh3Fez0QZ9pkaekmHkfBzY=";
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
