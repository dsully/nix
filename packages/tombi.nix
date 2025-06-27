{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "tombi";
    version = "0.4.15";

    src = fetchFromGitHub {
      owner = "tombi-toml";
      repo = pname;
      rev = "44292bdc217bbf99dfb975966ece377609b814e8";
      hash = "sha256-Njj7H08HEGNzzjG72WACAIPEzOqBH3GGkLn+tbTXGNk=";
    };

    cargoHash = "sha256-XfpJqTJhv++TATq2PbM448AdRXg5Yog90HYNaXkTwNs=";
    useFetchCargoVendor = true;
    doCheck = false;

    meta = {
      description = "TOML Formatter / Linter / Language Server";
      homepage = "https://github.com/tombi-toml/tombi";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
