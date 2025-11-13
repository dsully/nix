{pkgs, ...}:
with pkgs; let
  dists = {
    aarch64-darwin = {
      platform = "macosx_11_0_arm64";
      hash = "sha256-N8w4lAs9h4xomka3zvNT7vofJhvwsq1D7pUeT7HOWeQ=";
    };
    x86_64-linux = {
      platform = "manylinux_2_17_x86_64.manylinux2014_x86_64";
      hash = "sha256-StDSiNqFJxRYb6gCJ+/fjNMYdEtT+/y+7ErK3p9YBiI=";
    };
  };

  d = dists.${system} or (throw "Unsupported system: ${system}");
in
  python3.pkgs.buildPythonPackage rec {
    pname = "pyrefly";
    version = "0.41.2";
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
