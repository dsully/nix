{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.27.0";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-Zfqow12RJnQxljRl/RcOkvdy/RnlGYBCCE0riz02XMk=";
    };

    cargoHash = "sha256-nxe+ZLDoGFSO4rKvyfVYxohcs0/2Ht+0rC+n4Irx7/Q=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
