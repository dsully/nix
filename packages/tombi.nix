{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "28b2509c1fc2ce9fe3a05e292dd5593a2f069933";
    pname = "tombi";
    version = "0.4.16-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "tombi-toml";
      repo = pname;
      hash = "sha256-YYdJsngMLxL47eIeE2fu47u14CINr7Y7whV/QXniIK0=";
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
