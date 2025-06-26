{pkgs, ...}:
with pkgs;
  python3.pkgs.buildPythonApplication rec {
    pname = "bake";
    version = "1.2.4";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "EbodShojaei";
      repo = "bake";
      rev = "14ea4bd03f584778a0dd511d54e3df09f92e927a";
      hash = "sha256-RzM3HC3lYq93mngpqNCohcPMISWQ4+Lwa1V88S0O0To=";
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
