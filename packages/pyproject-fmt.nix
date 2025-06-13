{pkgs, ...}:
with pkgs;
  python3.pkgs.buildPythonApplication rec {
    pname = "pyproject-fmt";
    version = "2.6.0";
    format = "wheel";

    src = fetchPypi {
      pname = "pyproject_fmt";
      version = "2.6.0";
      hash = "sha256-ZkCDD1n2XSaqlT9c6IfSO5NZhWpdDhDTPHVrlnayKd8=";
    };

    meta = {
      description = "Format your pyproject.toml file";
      homepage = "https://github.com/tox-dev/toml-fmt";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
