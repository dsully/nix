{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.9.5";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-hD3PyUOlAfs/py77sLU6B/wN/ZFtYxzvJar/inRnWNs=";
    };

    cargoHash = "sha256-Z020zYSaAYAbP4rc0ZZ80Ys6FIlgibSNyAIVeBWR86U=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
