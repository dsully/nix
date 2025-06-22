{pkgs, ...}:
with pkgs;
  python3.pkgs.buildPythonApplication rec {
    pname = "bake";
    version = "1.1.3";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "EbodShojaei";
      repo = "bake";
      rev = "16f792bc7e16898ff081dc19a6d910705fba685a";
      hash = "sha256-oUdMbTbY3mfSIiGjHCDf1aRuq6Uy9MSbcO35lyvwRjU=";
    };

    build-system = [
      python3.pkgs.hatchling
    ];

    dependencies = with python3.pkgs; [
      rich
      typer
    ];

    meta = {
      description = "Mbake is a Python-based Makefile formatter and linter that enforces consistent formatting according to Makefile best practices.";
      homepage = "https://github.com/EbodShojaei/bake";
      changelog = "https://github.com/EbodShojaei/bake/blob/${src.rev}/CHANGELOG.md";
      license = lib.licenses.mit;
      mainProgram = "bake";
    };
  }
