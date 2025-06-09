{
  perSystem,
  pkgs,
  ...
}:
with pkgs;
  python3.pkgs.buildPythonApplication rec {
    pname = "pyproject-fmt";
    version = "2.5.1";
    pyproject = true;

    src = fetchPypi {
      pname = "pyproject_fmt";
      inherit version;
      hash = "sha256-x9/h9izJH99+xzBDsSwN8DqagozgkGf6S7Ui/qWyQmk=";
    };

    cargoDeps = rustPlatform.fetchCargoVendor {
      inherit src;
      name = "${pname}-${version}";
      hash = "sha256-0AK/5tukGq0tYfIbgdVDNu3pUVvZpP8rbsCRGxtztPA=";
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
      homepage = "https://pypi.org/project/pyproject-fmt/";
      license = lib.licenses.mit;
      mainProgram = "pyproject-fmt";
    };
  }
