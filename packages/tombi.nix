{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "b72375ee350034c527c2df81601f02d1aaf3a5dd";
    pname = "tombi";
    version = "0.4.16-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "tombi-toml";
      repo = pname;
      hash = "sha256-cr0RJFYvPTlEYwp0hqldREAg/Bxmw2k8b1xKRaKRjWg=";
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
