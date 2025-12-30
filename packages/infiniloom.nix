{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "infiniloom";
    version = "0.5.4";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-NJQs89Y4UhoeOCkb8L4fbWQtrlc674I4T91MFfNfNv0=";
    };

    cargoHash = "sha256-3Bz3k/ULGAF1+okhib1jM4bUgBP7ZUs8+gUlmNk5E5g=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/infiniloom";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
