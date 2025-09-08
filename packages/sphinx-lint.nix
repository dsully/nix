{pkgs, ...}:
with pkgs;
  python3.pkgs.buildPythonApplication rec {
    pname = "sphinx-lint";
    version = "1.0.0";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "sphinx-contrib";
      repo = pname;
      rev = "a2753ebfa20d2d56d5fa0bbe4e86cbf9e06e03d7";
      hash = "sha256-nfXtqYzWkvu50kiUmnTpyVL1XQA1BDEKlldoei3q2Ks=";
    };

    build-system = [
      python3.pkgs.hatch-vcs
      python3.pkgs.hatchling
    ];

    dependencies = with python3.pkgs; [
      polib
      regex
    ];

    meta = {
      description = "Check for stylistic and formal issues in .rst and .py files included in the documentation";
      homepage = "https://github.com/sphinx-contrib/sphinx-lint";
      mainProgram = pname;
    };
  }
