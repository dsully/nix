{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "tombi";
    version = "0.4.16";

    src = fetchFromGitHub {
      owner = "tombi-toml";
      repo = pname;
      rev = "95ed653fb248a29080f5e1e5dd014b24d59fae25";
      hash = "sha256-RFMz5w2snV5DlXaquv7mt6zmqs/wJZUCMFMjteVIYjA=";
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
