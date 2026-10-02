{
  buildNpmPackage,
  fetchFromGitHub,
  lib,
}:
buildNpmPackage {
  pname = "meridian-plugin-opencode-scrub";
  version = "0.2.0-77316d2b";

  src = fetchFromGitHub {
    owner = "rynfar";
    repo = "meridian-plugin-opencode-scrub";
    rev = "77316d2ba4ed77ef3d5f12e40256ba1c3699d85a";
    hash = "sha256-aCfNkviWzl+uBJV9Nu7baz9+Grdr/d+G9CVmFrVHp88=";
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
