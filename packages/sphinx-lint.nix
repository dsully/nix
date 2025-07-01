{pkgs, ...}:
with pkgs;
  python3.pkgs.buildPythonApplication rec {
    pname = "sphinx-lint";
    version = "1.0.0";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "sphinx-contrib";
      repo = pname;
      rev = "688bef9c9500aa75dc33b0ffc064de8753d56819";
      hash = "sha256-UW50lFxP4HEdg2vxMTRrNHNNaSFCi72IghBPjtkKQYg=";
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
