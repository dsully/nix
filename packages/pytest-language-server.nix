{pkgs, ...}:
with pkgs; let
  dists = {
    aarch64-darwin = {
      platform = "macosx_11_0_arm64";
      hash = "sha256-yEqy6iiA6NQjq+3CTHuUg/7zN1TYOnlVXY/tMV9GaEY=";
    };
    x86_64-linux = {
      platform = "manylinux_2_17_x86_64.manylinux2014_x86_64";
      hash = "sha256-y5XMpgZQvTvuZL21hiHwcqlV64Z6l6KnxzU0HuUJasU=";
    };
  };

  d = dists.${system} or (throw "Unsupported system: ${system}");
in
  python3.pkgs.buildPythonPackage rec {
    pname = "pytest-language-server";
    version = "0.17.0";
    format = "wheel";

    src = fetchPypi {
      inherit version format;
      inherit (d) hash platform;
      pname = "pytest_language_server";
      abi = "none";
      python = "py3";
      dist = "py3";
    };

    meta = {
      description = "A blazingly fast Language Server Protocol implementation for pytest";
      homepage = "https://pypi.org/project/pytest-language-server/";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
