{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "ed9cdba29ce916e406361ce3acb7687fac996d15";
    pname = "tombi";
    version = "0.4.16-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "tombi-toml";
      repo = pname;
      hash = "sha256-4s65aig60ZTt2ubFX+Rp+IvpYnmLJz1Wnb4FguwSqEM=";
    };

    cargoHash = "sha256-OPcqJtIW4jQn2UM+Sy9CAxYBpF5nqVczQsHZ75nx9qU=";
    useFetchCargoVendor = true;
    doCheck = false;

    meta = {
      description = "TOML Formatter / Linter / Language Server";
      homepage = "https://github.com/tombi-toml/tombi";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
