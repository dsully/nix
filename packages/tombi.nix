{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "f0e09ed7b7d50e101d51704c4aea624d0ce9e72a";
    pname = "tombi";
    version = "0.4.16-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "tombi-toml";
      repo = pname;
      hash = "sha256-sk84WG/hqLG0MU5XcyUJCcVOmTfk+Y+VI1TydkCdQxo=";
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
