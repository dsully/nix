{
  lib,
  rustPlatform,
  fetchCrate,
}:
rustPlatform.buildRustPackage rec {
  pname = "clean-dev-dirs";
  version = "2.7.1";

  src = fetchCrate {
    inherit pname version;
    hash = "sha256-64BWCT7kC9BqM14LeJtkwB2dzg5TKJPjgsUPdr1wr8c=";
  };

  cargoHash = "sha256-Wa0sYRG1ifb01sFeM8wrMPr08+pzocLOfA6PRyVwhc8=";
  doCheck = false;

  meta = {
    description = "A fast and efficient CLI tool for recursively cleaning Rust target/ and Node.js node_modules/ directories to reclaim disk space";
    homepage = "https://github.com/TomPlanche/clean-dev-dirs";
    license = with lib.licenses; [asl20 mit];
    mainProgram = pname;
  };
}
