{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "tombi";
    version = "0.4.16";

    src = fetchFromGitHub {
      owner = "tombi-toml";
      repo = pname;
      rev = "1b5bc84d37f761ba36689132b83c2b3b78aa273c";
      hash = "sha256-DOHJfeK5GLRsF1Gok7Ewu/DSfd/9MfESlzTyORCSOGQ=";
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
