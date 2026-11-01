{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "magic-opener";
  version = "0.3.6";
  rev = "40041924585488ce943bca5b42e34360a8130354";

  src = fetchFromGitHub {
    inherit rev;
    owner = "dsully";
    repo = pname;
    hash = "sha256-MWyLVskGyzTTA0SqcgWanefw6hqP2YjSkz0BWhclhjk=";
  };

  cargoHash = "sha256-KySq0j504cit4IsrO7Ff1YYHAts2EKUCBqFi3WljVoE=";
  doCheck = false;

  meta = {
    description = "A tool for opening the right thing in the right place";
    homepage = "https://github.com/dsully/magic-opener";
    license = lib.licenses.mit;
    mainProgram = "open";
  };
}
