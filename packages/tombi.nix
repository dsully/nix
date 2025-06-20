{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "tombi";
    version = "0.4.10";

    src = fetchFromGitHub {
      owner = "tombi-toml";
      repo = "tombi";
      rev = "a458538a71b67968fa986cb07818df1ca0378f02";
      hash = "sha256-xSxNisKJAA9lvAq1KzTxh3Lhc+p3ol55XzSKjg7m7RY=";
    };

    cargoHash = "sha256-y2pwEu006PsVmJKesAD/UDDbhdNre79AKZRAmFEZVDQ=";
    useFetchCargoVendor = true;
    doCheck = false;

    meta = {
      description = "TOML Formatter / Linter / Language Server";
      homepage = "https://github.com/tombi-toml/tombi";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
