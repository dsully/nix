{pkgs, ...}:
with pkgs; let
  dists = {
    aarch64-darwin = {
      platform = "macosx_11_0_arm64";
      hash = "sha256-/hghe/ruAmsGKX6XTXwGBRKf9Km509YSHS2wvG3rFe8=";
    };
    x86_64-linux = {
      platform = "manylinux_2_17_x86_64.manylinux2014_x86_64";
      hash = "sha256-AaiQ3p9FX6uAxZyoc9AGtx0Icx6KxFz9KnCzU00R4XE=";
    };
  };

  d = dists.${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
  python3.pkgs.buildPythonPackage rec {
    pname = "pytest-language-server";
    version = "0.18.0";
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
