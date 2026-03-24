{
  lib,
  rustPlatform,
  fetchCrate,
}:
rustPlatform.buildRustPackage rec {
  pname = "clean-dev-dirs";
  version = "2.8.0";

  src = fetchCrate {
    inherit pname version;
    hash = "sha256-E26t+vItr4OSH4jJ8FohQqaQZ+v9CJ91w7TkAu41tyw=";
  };

  cargoHash = "sha256-MEdA1qb7fqQnspvZe+kimBuvBxK/Wf5ZtDR+FPrIOPY=";
  doCheck = false;

  meta = {
    description = "A fast and efficient CLI tool for recursively cleaning Rust target/ and Node.js node_modules/ directories to reclaim disk space";
    homepage = "https://github.com/TomPlanche/clean-dev-dirs";
    license = with lib.licenses; [asl20 mit];
    mainProgram = pname;
  };
}
