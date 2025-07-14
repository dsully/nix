{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "da29a199b49ee95271052d0461dc522a8210d1de";
    pname = "tombi";
    version = "0.4.16-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "tombi-toml";
      repo = pname;
      hash = "sha256-ekwVaPGoPxv18XDKmSgI6uKI913tIrjmPvipJB7gBuQ=";
    };

    cargoHash = "sha256-2dLkZnGOVclp0EnAKsVH8HRTOXtq/1ADkoS5UiLGGnQ=";
    useFetchCargoVendor = true;
    doCheck = false;

    meta = {
      description = "TOML Formatter / Linter / Language Server";
      homepage = "https://github.com/tombi-toml/tombi";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
