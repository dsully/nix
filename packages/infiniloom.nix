{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "infiniloom";
    version = "0.6.1";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-vjc1tyYu8uJxWFxzNcst5FhBEsSAKAjSIFPcCvdJkvg=";
    };

    cargoHash = "sha256-cuKjnKUoAUu3EqgJvEUgaFbarhIBdRY+ZsmtMcQhl+w=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/infiniloom";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
