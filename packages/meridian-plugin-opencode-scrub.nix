{
  buildNpmPackage,
  fetchFromGitHub,
  lib,
}:
buildNpmPackage {
  pname = "meridian-plugin-opencode-scrub";
  version = "0.2.0-4b410c5a";

  src = fetchFromGitHub {
    owner = "rynfar";
    repo = "meridian-plugin-opencode-scrub";
    rev = "4b410c5a04470f7daa0f61ad0e50a6e3f0205f5c";
    hash = "sha256-dbjnY7Y1vU6i37/90qhUnw5jnVDg0rK4tzCKhalLvQE=";
  };

  npmDepsHash = "sha256-2qlUw26C0toMeJD0mlt+uh317fyUEOaQlXJpj1s6nLs=";

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
