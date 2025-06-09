{pkgs, ...}:
with pkgs;
  python3.pkgs.buildPythonApplication rec {
    pname = "sphinx-lint";
    version = "1.0.0";
    pyproject = true;

    src = fetchPypi {
      pname = "sphinx_lint";
      inherit version;
      hash = "sha256-bq/bRBcs5Sb0Bb82xxPrJG8TQOwtZn5ymOJIftdt7NI=";
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
      homepage = "https://pypi.org/project/sphinx-lint/";
      mainProgram = "sphinx-lint";
    };
  }
