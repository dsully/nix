{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "codesort";
    version = "737e325f";

    src = fetchFromGitHub {
      owner = "Canop";
      repo = "codesort";
      rev = "737e325f8732730221d2322ee9557807585f1726";
      hash = "sha256-sBq/78DvGv0B+7EZ23CnYdaPMX8Om/cfy19cU20STp8=";
    };

    cargoHash = "sha256-OB0JgkzviBqAkXdeiP6lYhiQxPSx3BcFFKBVvgTxWKk=";
    doCheck = false;

    meta = {
      description = "Codesort sorts code";
      homepage = "https://github.com/Canop/codesort";
      changelog = "https://github.com/Canop/codesort/blob/${src.rev}/CHANGELOG.md";
      mainProgram = pname;
    };
  }
