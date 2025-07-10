{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "e3e33f284cf19829f5b4d6bc3ca36573c18ff389";
    pname = "tombi";
    version = "0.4.16-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "tombi-toml";
      repo = pname;
      hash = "sha256-fAeHdc/ZjuAxX66wHfuwj2O8lTDFQAlzsOjhEk2wYTM=";
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
