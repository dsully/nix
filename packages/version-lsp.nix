{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "version-lsp";
    version = "0.4.0";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-fvMzTDrHlwS+kKVaxjemcdMXw9z2xBto8rbgZXhqMSY=";
    };

    cargoHash = "sha256-1xM89pzGIBfhQflO5/9s7nZYF5ogHkje0ApEua0aOyY=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/version-lsp";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
