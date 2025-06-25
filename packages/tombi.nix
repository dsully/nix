{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "tombi";
    version = "0.4.13";

    src = fetchFromGitHub {
      owner = "tombi-toml";
      repo = "tombi";
      rev = "cf3402bbd2ad21a166949ae7a2f18b5f664c1bad";
      hash = "sha256-NjJolcjjntVrgeO2FZ3g9nRzPN7nKmyyFpm0690OTFI=";
    };

    cargoHash = "sha256-XfpJqTJhv++TATq2PbM448AdRXg5Yog90HYNaXkTwNs=";
    useFetchCargoVendor = true;
    doCheck = false;

    meta = {
      description = "TOML Formatter / Linter / Language Server";
      homepage = "https://github.com/tombi-toml/tombi";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
