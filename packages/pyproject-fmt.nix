{
  perSystem,
  pkgs,
  ...
}:
with pkgs;
  python3.pkgs.buildPythonApplication rec {
    pname = "pyproject-fmt";
    version = "2.6.0";
    pyproject = true;

    src = fetchPypi {
      pname = "pyproject_fmt";
      version = "2.6.0";
      hash = "sha256-ZkCDD1n2XSaqlT9c6IfSO5NZhWpdDhDTPHVrlnayKd8=";
    };

    cargoDeps = rustPlatform.fetchCargoVendor {
      inherit src;
      name = "${pname}-${version}";
      hash = "sha256-vK4+Pgi1kCilBm7RhWTCom/Q3u/DHf6LTbRmQI+8IqU=";
    };

    build-system = [
      cargo
      rustPlatform.cargoSetupHook
      rustPlatform.maturinBuildHook
      rustc
    ];

    dependencies = [
      perSystem.self.toml-fmt-common
    ];

    pythonImportsCheck = [
      "pyproject_fmt"
    ];

    meta = {
      description = "Format your pyproject.toml file";
      homepage = "https://github.com/tox-dev/toml-fmt";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
