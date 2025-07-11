{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "1d28ca805ffba7d490c64c67fc36f5a8501675e8";
    pname = "tombi";
    version = "0.4.16-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "tombi-toml";
      repo = pname;
      hash = "sha256-XD/5pw+klyUoVGB9P6MMi6rcCy0YgNvLBb8VzR91+Fw=";
    };

    cargoHash = "sha256-vtaif74fYBCP0AAL1NFXxHJ/casZGwTJsmwZLiWqY64=";
    useFetchCargoVendor = true;
    doCheck = false;

    meta = {
      description = "TOML Formatter / Linter / Language Server";
      homepage = "https://github.com/tombi-toml/tombi";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
