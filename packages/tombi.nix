{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "tombi";
    version = "0.4.32";

    src = fetchFromGitHub {
      owner = "tombi-toml";
      repo = pname;
      rev = "bd5944a8f0a4e8029bc752e1c0483030dd2d37df";
      hash = "sha256-w4hPAUwEOLjCPJhBQU/sAfOa2j1ga2dvnXEB7LRVYTA=";
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
