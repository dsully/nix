{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  rev = "0a806625b18221e90c8eb02d13d0794e4db7238d";
  pname = "geil";
  version = "0.0.1-alpha.1-${rev}";

  src = fetchFromGitHub {
    inherit rev;
    owner = "Nukesor";
    repo = pname;
    hash = "sha256-IHflpYDw7++gE8wHYNm+kAm39TltY1Tgq+JooKO4Kb8=";
  };

  cargoHash = "sha256-pVG2dyjZSgzcA1zAxoZExyjpwZG0wz5NdIwY/KV8hcQ=";
  doCheck = false;

  meta = {
    description = "Rocket: A tool to update your repositories and for keeping them clean";
    homepage = "https://github.com/Nukesor/geil";
    license = lib.licenses.mit;
    mainProgram = pname;
  };
}
