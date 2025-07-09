{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "7c9fb9e46b84c83890503214c8afc53798185436";
    pname = "tombi";
    version = "0.4.16-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "tombi-toml";
      repo = pname;
      hash = "sha256-EVr4qybyLtGgNde0uuNoQYv2jugNGJups5HUcs7n4KI=";
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
