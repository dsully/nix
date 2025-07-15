{pkgs, ...}:
with pkgs; let
  pkgsWithRust = pkgs.extend (import (builtins.fetchTarball {
    url = "https://github.com/oxalica/rust-overlay/archive/master.tar.gz";
    sha256 = "sha256-f4XVgqkWF1vSzPbOG5xvi4aAd/n1GwSNsji3mLMFwYQ=";
  }));
in
  rustPlatform.buildRustPackage rec {
    rev = "473c96ae803d437d3004c68362603d630499d7b2";
    pname = "pyrefly";
    version = "0.24.0-${rev}";

    nativeBuildInputs = [pkgsWithRust.rust-bin.nightly.latest.default];

    src = fetchFromGitHub {
      inherit rev;
      owner = "facebook";
      repo = pname;
      hash = "sha256-EsH6YG+wEMv75Thi/cbCOLnCTtZJV1AucueFduuUF3M=";
    };

    cargoHash = "sha256-9OocrBmKTkrd3kAm7PQksaml7Mi79uLDAVvTKzd8CGY=";
    doCheck = false;
    useFetchCargoVendor = true;

    meta = {
      description = "A fast type checker and IDE for Python";
      homepage = "https://github.com/facebook/pyrefly";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
