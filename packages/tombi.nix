{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "769382ce5600ecfd4e69b8b031680b2b4d9518a1";
    pname = "tombi";
    version = "0.4.16-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "tombi-toml";
      repo = pname;
      hash = "sha256-jRal4zwuP3kniS4vfS97sYKuXC+3I3kLMaBKbpa3ZUg=";
    };

    cargoHash = "sha256-JZlWYzKK6un1IMpHZ/o7SibLHROIitDpVgIRds3m5Ns=";
    useFetchCargoVendor = true;
    doCheck = false;

    meta = {
      description = "TOML Formatter / Linter / Language Server";
      homepage = "https://github.com/tombi-toml/tombi";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
