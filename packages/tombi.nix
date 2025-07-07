{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "12b10923d9709364fd7bf58d383fd21b727be19c";
    pname = "tombi";
    version = "0.4.16-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "tombi-toml";
      repo = pname;
      hash = "sha256-s+UGy8vy4gS/YRpzXR+JRtsEaXlmmgjwvgmEX4wJaOI=";
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
