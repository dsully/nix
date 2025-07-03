{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "tombi";
    version = "0.4.16";

    src = fetchFromGitHub {
      owner = "tombi-toml";
      repo = pname;
      rev = "6482be30f4df3db314cf3ddbb9055d156611ce49";
      hash = "sha256-q9NoYLHnvUCsRApMIhVaiomkLwHgtaYzosuPflr26LQ=";
    };

    cargoHash = "sha256-QXam/i+ptKTom1tXHiABTv3wk+BWCBV+DDaY3hYVg6U=";
    useFetchCargoVendor = true;
    doCheck = false;

    meta = {
      description = "TOML Formatter / Linter / Language Server";
      homepage = "https://github.com/tombi-toml/tombi";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
