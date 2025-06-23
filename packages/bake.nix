{pkgs, ...}:
with pkgs;
  python3.pkgs.buildPythonApplication rec {
    pname = "bake";
    version = "1.1.3";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "EbodShojaei";
      repo = "bake";
      rev = "2655ad9546750772c81ca66ad08b3e498e792b39";
      hash = "sha256-5Bw1dSbHLY5fX0v30IqD12zl+vgC63tleJQs6LNP9/0=";
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
