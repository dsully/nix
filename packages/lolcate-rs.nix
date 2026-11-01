{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "lolcate-rs";
  version = "0.2.4";

  src = fetchFromGitHub {
    owner = "dsully";
    repo = pname;
    rev = "334921bd96c92f5e1840ceb1e56d5a01d1f3897a";
    hash = "sha256-bc9snuZ8ppIRenIeCusQPCZnKzW03vfSDCY2LdRjSAU=";
  };

  cargoHash = "sha256-mynyuvomORKl3mnRoC1CXIcvYh4hWkgfrRj+5pgtPzs=";
  doCheck = false;

  meta = {
    description = "Lolcate -- A comically fast way of indexing and querying your filesystem. Replaces locate / mlocate / updatedb. Written in Rust";
    homepage = "https://github.com/dsully/lolcate-rs";
    license = lib.licenses.gpl3Only;
    maintainers = ["dsully"];
    mainProgram = "lolcate";
  };
}
