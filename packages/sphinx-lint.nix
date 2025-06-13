{pkgs, ...}:
with pkgs;
  python3.pkgs.buildPythonApplication {
    pname = "sphinx-lint";
    version = "1.0.0";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "sphinx-contrib";
      repo = "sphinx-lint";
      rev = "9c97dd9b26f393464c3375f8cdc065c2c9ff3839";
      hash = "sha256-Vvr158lrsF8WCGK4fYsnaaOYI2VPRrYu1aPq8Yu2M5I=";
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
      mainProgram = "sphinx-lint";
    };
  }
