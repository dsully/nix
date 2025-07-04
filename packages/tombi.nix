{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "4753decba90e5fff24c1d44acd60bd48cdd9d30f";
    pname = "tombi";
    version = "0.4.16-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "tombi-toml";
      repo = pname;
      hash = "sha256-FZijcE+NrRyV0dFL7UZSabYcQwW3vuURne67BFS4Sys=";
    };

    cargoHash = "sha256-is3dAdkaXEUvju0SF3yAyfuMU2SvllE+42ebUHNyOR0=";
    useFetchCargoVendor = true;
    doCheck = false;

    meta = {
      description = "TOML Formatter / Linter / Language Server";
      homepage = "https://github.com/tombi-toml/tombi";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
