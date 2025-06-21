{pkgs, ...}:
with pkgs;
  python3.pkgs.buildPythonApplication rec {
    pname = "bake";
    version = "1.1.1";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "EbodShojaei";
      repo = "bake";
      rev = "cd52747cf3fd5296f40541475d1b1d53f27f31a8";
      hash = "sha256-IVnrcK+tDPTDpBh9AX23SDvhTqb8uxubOmZlXmLA5KE=";
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
