{pkgs, ...}:
with pkgs;
  python3.pkgs.buildPythonApplication rec {
    pname = "bake";
    version = "1.2.3";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "EbodShojaei";
      repo = "bake";
      rev = "349b01464cff355bdf2ed82ba355ff1eede94b3a";
      hash = "sha256-0YlBHcO3qItM+kh/+UkQkoezuHgNLVmAZzrJVdfuXp4=";
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
