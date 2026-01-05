{pkgs, ...}:
with pkgs; let
  dists = {
    aarch64-darwin = {
      platform = "macosx_11_0_arm64";
      hash = "sha256-f/m3Ao2QQOE/V/q4UMD2lEH1B7T9J0+Pm69Wmdt8Wy4=";
    };
    x86_64-linux = {
      platform = "manylinux_2_17_x86_64.manylinux2014_x86_64";
      hash = "sha256-4cCnzFfrBgVa3/4sIV9KMuuyW0cil4PvRmkXv0L1EuU=";
    };
  };

  d = dists.${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
  python3.pkgs.buildPythonPackage rec {
    pname = "pyrefly";
    version = "0.47.0";
    format = "wheel";

    src = fetchPypi {
      inherit pname version format;
      inherit (d) hash platform;
      abi = "none";
      python = "py3";
      dist = "py3";
    };

    meta = {
      description = "A fast Python type checker written in Rust";
      homepage = "https://pypi.org/project/pyrefly";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
