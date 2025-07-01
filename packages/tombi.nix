{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "tombi";
    version = "0.4.16";

    src = fetchFromGitHub {
      owner = "tombi-toml";
      repo = pname;
      rev = "18e7ed8c686278c00c1fc8152994cc292960f349";
      hash = "sha256-SbBPuAOMSZmwtqzvTQ/A5vhXeqeIiSazt7UtEUrMyr0=";
    };

    cargoHash = "sha256-P4t0aMQVo7962SxgT7tUv6G+rHgO2PbE8bEPAI63rRQ=";
    useFetchCargoVendor = true;
    doCheck = false;

    meta = {
      description = "TOML Formatter / Linter / Language Server";
      homepage = "https://github.com/tombi-toml/tombi";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
