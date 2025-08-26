{pkgs, ...}:
with pkgs;
  python3.pkgs.buildPythonApplication rec {
    pname = "sphinx-lint";
    version = "1.0.0";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "sphinx-contrib";
      repo = pname;
      rev = "0e9f6fc368b3d660e1826d570690f937ed3df706";
      hash = "sha256-Xk4V1gsPllKkKbZffWChMJVeNt+j/sOYHcNP3OMuvyE=";
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
