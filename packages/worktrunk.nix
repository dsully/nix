{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.21.0";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-gD38usP0cxjwT3ee2fbpl4Q1ZH2vtlSlU1dUEd45tY0=";
    };

    cargoHash = "sha256-JKHv6+wDTVdPjeidhCtS7c0tUoJNvQB7JWOC5VIc3a0=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
