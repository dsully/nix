{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "clean-dev-dirs";
    version = "2.5.0";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-ydMdxLbGjPpV7P23itVF+pwNvN1MIwQii1gA9HXc+cY=";
    };

    cargoHash = "sha256-YXHRmvGMI7+L7dVhAF2dVMwjKQ89yOgaAO1sq6+bsBo=";
    doCheck = false;

    meta = {
      description = "A fast and efficient CLI tool for recursively cleaning Rust target/ and Node.js node_modules/ directories to reclaim disk space";
      homepage = "https://github.com/TomPlanche/clean-dev-dirs";
      license = with lib.licenses; [asl20 mit];
      mainProgram = pname;
    };
  }
