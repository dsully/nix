{pkgs, ...}:
with pkgs; let
  dists = {
    aarch64-darwin = {
      platform = "macosx_11_0_arm64";
      hash = "sha256-s8Raa6l4Sx3Ydu+gJ3I12chLq3+pe1tLPgbSqGK7ISo=";
    };
    x86_64-linux = {
      platform = "manylinux_2_17_x86_64.manylinux2014_x86_64";
      hash = "sha256-IFNmI1xcdpjsZAqzw9FZmU1BSUyaS5+Wya/sAi8KOhQ=";
    };
  };

  d = dists.${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
  python3.pkgs.buildPythonPackage rec {
    pname = "pytest-language-server";
    version = "0.20.0";
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
