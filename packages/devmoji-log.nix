{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  libgit2,
  zlib,
}:
rustPlatform.buildRustPackage rec {
  pname = "devmoji-log";
  version = "0.0.3";

  src = fetchFromGitHub {
    owner = "dsully";
    repo = pname;
    rev = "51628be6ae753644c275fd2fed432eeda614e57d";
    hash = "sha256-HPPZhMEzLE4RPCn5gjFaXMqsnv0qh+Nz7IhJ3cy7aKY=";
  };

  cargoHash = "sha256-I+Hw2Tkr05tvPM75ad1oMpis520myMVHTxTJ/ygEjhw=";
  doCheck = false;

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    libgit2
    zlib
  ];

  meta = {
    description = "Display Git commit history with conventional commit types and gitmojis";
    homepage = "https://github.com/dsully/devmoji-log";
    license = lib.licenses.mit;
    maintainers = ["dsully"];
    mainProgram = pname;
  };
}
