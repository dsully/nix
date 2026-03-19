{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  rev = "7b3eb507ca03e7765e836e13f40094a4b32e3042";
  pname = "geil";
  version = "0.0.1-alpha.1-${rev}";

  src = fetchFromGitHub {
    inherit rev;
    owner = "Nukesor";
    repo = pname;
    hash = "sha256-y1452ISnyMXdyPpyIlcpZx9Cj6jNI5do41w4fAB1Xn8=";
  };

  cargoHash = "sha256-dLeF3n9JdH0GbyKGXrraTsVUZHaIoUYPQgdjxiNb074=";
  doCheck = false;

  meta = {
    description = "Rocket: A tool to update your repositories and for keeping them clean";
    homepage = "https://github.com/Nukesor/geil";
    license = lib.licenses.mit;
    mainProgram = pname;
  };
}
