{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "tombi";
    version = "0.4.32";

    src = fetchFromGitHub {
      owner = "tombi-toml";
      repo = pname;
      rev = "8d2953607ac7bad68b0b2bdbf3b6b23d2230fd88";
      hash = "sha256-aruGr9eG2MHA2seC8nsGwlOyn4Sj5TtUozuFcOWeoTE=";
    };

    cargoHash = "sha256-2dLkZnGOVclp0EnAKsVH8HRTOXtq/1ADkoS5UiLGGnQ=";
    useFetchCargoVendor = true;
    doCheck = false;

    meta = {
      description = "TOML Formatter / Linter / Language Server";
      homepage = "https://github.com/tombi-toml/tombi";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
