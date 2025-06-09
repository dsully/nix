{pkgs, ...}:
with pkgs;
  python3.pkgs.buildPythonApplication rec {
    pname = "toml-fmt-common";
    version = "1.0.1";
    pyproject = true;

    src = fetchPypi {
      pname = "toml_fmt_common";
      inherit version;
      hash = "sha256-einpnlJ/+sRWBDKWoPHYwDqqGwYWe9Oa1ePMUEHzHBc=";
    };

    build-system = [
      python3.pkgs.hatch-vcs
      python3.pkgs.hatchling
    ];

    dependencies = with python3.pkgs; [
      tomli
    ];

    pythonImportsCheck = [
      "toml_fmt_common"
    ];

    meta = {
      description = "Common logic to the TOML formatter";
      homepage = "https://pypi.org/project/toml-fmt-common";
      license = lib.licenses.mit;
      mainProgram = "toml-fmt-common";
    };
  }
