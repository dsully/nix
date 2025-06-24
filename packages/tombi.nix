{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "tombi";
    version = "0.4.13";

    src = fetchFromGitHub {
      owner = "tombi-toml";
      repo = "tombi";
      rev = "c051f9399c3bfad663f7ce166d3e799ddf11c073";
      hash = "sha256-ZJ84JyIdHOJsksqUVYbFbND+Zif5L7j2UCmKVQTJetI=";
    };

    cargoHash = "sha256-MVfUey9WG2SN6FwN7phR/1+W7XG+W3JvafAHLaCNvSo=";
    useFetchCargoVendor = true;
    doCheck = false;

    meta = {
      description = "TOML Formatter / Linter / Language Server";
      homepage = "https://github.com/tombi-toml/tombi";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
