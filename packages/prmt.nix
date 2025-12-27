{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "prmt";
    rev = "09518171e738eb72fa4971f9f1108beddf47cfbb";
    version = "0.1.7-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "3axap4eHko";
      repo = "prmt";
      hash = "sha256-iHRAIOm5wks/Go5Pfa77oQe2UVAYzJV3XGf36VbELsQ=";
    };

    cargoHash = "sha256-onCRbPBX5ELXV51P5qXQfkV3uGSXtR232sXMWa6WqVI=";
    doCheck = false;

    meta = {
      description = "Ultra-fast, customizable shell prompt generator";
      homepage = "https://github.com/3axap4eHko/prmt";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
