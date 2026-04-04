{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  rev = "f056865114d081ea4ef7bdc889f98be2dbc01add";
  pname = "geil";
  version = "0.0.1-alpha.1-${rev}";

  src = fetchFromGitHub {
    inherit rev;
    owner = "Nukesor";
    repo = pname;
    hash = "sha256-PasAcW+fgm4o2NsxKlLDEjtuJ1O6jAoZ9f2GJd3kERw=";
  };

  cargoHash = "sha256-7SsvnBpjVGbzxiRGcPvKuQAjXCaG9+HdXeNaqEqFjlQ=";
  doCheck = false;

  meta = {
    description = "Rocket: A tool to update your repositories and for keeping them clean";
    homepage = "https://github.com/Nukesor/geil";
    license = lib.licenses.mit;
    mainProgram = pname;
  };
}
