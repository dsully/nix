{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "9f18417aaf89061611a514e21b7a0f4fad967940";
    pname = "tombi";
    version = "0.4.16-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "tombi-toml";
      repo = pname;
      hash = "sha256-Rpe01Hv21QB6U5aa4A/VscM7v/WbTdtUKDCCNd6aW+c=";
    };

    cargoHash = "sha256-P66daCci9cgWzrHus3IcHifbPraeM+HLjs7xT1VfFlY=";
    useFetchCargoVendor = true;
    doCheck = false;

    meta = {
      description = "TOML Formatter / Linter / Language Server";
      homepage = "https://github.com/tombi-toml/tombi";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
