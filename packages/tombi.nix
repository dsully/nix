{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "tombi";
    version = "0.4.15";

    src = fetchFromGitHub {
      owner = "tombi-toml";
      repo = pname;
      rev = "4dc8e0181bd1f90b31de59ccb4eb7ae054685efb";
      hash = "sha256-cxQMCH0EK1WF5kVf796P6V1dcp7TwMM7x4VsI/lq8iw=";
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
