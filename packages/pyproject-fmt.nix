{pkgs, ...}:
with pkgs; let
  dists = {
    aarch64-darwin = {
      platform = "macosx_11_0_arm64";
      hash = "sha256-qzQBXGjcyk1MqPMJ/ntf71SDRNB/MjH6PcrnBuagIdQ=";
    };
    x86_64-linux = {
      platform = "manylinux_2_17_x86_64.manylinux2014_x86_64";
      hash = "sha256-iRngVSVSl5ccEs8CvOfRK5X9AhUZAQVN9SSy6AutSUg=";
    };
  };

  d = dists.${system} or (throw "Unsupported system: ${system}");

  toml-fmt-common = python3.pkgs.buildPythonPackage rec {
    pname = "toml-fmt-common";
    version = "1.0.1";
    format = "wheel";

    src = fetchPypi {
      abi = "none";
      dist = "py3";
      hash = "sha256-emVC42pxZ/qUuLmX0/jeutu0q3V8fXincwRXm9egzH0=";
      inherit format;
      pname = "toml_fmt_common";
      python = "py3";
      inherit version;
    };
  };
in
  python3.pkgs.buildPythonPackage rec {
    pname = "pyproject-fmt";
    version = "2.6.0";
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
