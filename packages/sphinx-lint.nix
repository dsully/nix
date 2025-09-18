{pkgs, ...}:
with pkgs;
  python3.pkgs.buildPythonApplication rec {
    pname = "sphinx-lint";
    version = "1.0.0";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "sphinx-contrib";
      repo = pname;
      rev = "f92a0070580547acd115e718c5599def8482da05";
      hash = "sha256-aYOWvVPbIks6k1gSNcw3YLnDWlNl/y2iIKy7eAJ5hUw=";
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
