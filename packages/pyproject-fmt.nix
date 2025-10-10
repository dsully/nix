{pkgs, ...}:
with pkgs; let
  dists = {
    aarch64-darwin = {
      platform = "macosx_11_0_arm64";
      hash = "sha256-5sgfJbzKpXYr9Feo8SLHLb1nzF6KgzhdzmVbVxzLr5I=";
    };
    x86_64-linux = {
      platform = "manylinux_2_17_x86_64.manylinux2014_x86_64";
      hash = "sha256-/w781CpuObmzO4KE3Fp/WTuBb+0AYYU5y2siQTejZXU=";
    };
  };

  d = dists.${system} or (throw "Unsupported system: ${system}");

  toml-fmt-common = python3.pkgs.buildPythonPackage rec {
    pname = "toml-fmt-common";
    version = "1.1.0";
    format = "wheel";

    src = fetchPypi {
      abi = "none";
      dist = "py3";
      hash = "sha256-kqlWxKv5wU5y1R5MIxSbJZaoSsDDR0hOfDYAiAfi4KM=";
      inherit format;
      pname = "toml_fmt_common";
      python = "py3";
      inherit version;
    };
  };
in
  python3.pkgs.buildPythonPackage rec {
    pname = "pyproject-fmt";
    version = "2.10.0";
    format = "wheel";

    src = fetchPypi {
      abi = "abi3";
      dist = "cp39";
      inherit (d) hash platform;
      inherit version format;
      pname = "pyproject_fmt";
      python = "cp39";
    };

    propagatedBuildInputs = [
      toml-fmt-common
    ];

    meta = {
      description = "Format your pyproject.toml file";
      homepage = "https://github.com/tox-dev/toml-fmt";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
