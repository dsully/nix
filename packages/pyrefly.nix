{pkgs, ...}:
with pkgs; let
  dists = {
    aarch64-darwin = {
      platform = "macosx_11_0_arm64";
      hash = "sha256-dHUh7YqZ2BSpdUs/mAZsiwPp7a21G3GEuGvEYU5LUKE=";
    };
    x86_64-linux = {
      platform = "manylinux_2_17_x86_64.manylinux2014_x86_64";
      hash = "sha256-v0pEcqQsf56q2ooW1hmDEUKZhH013s5o3mmNu5B3BxA=";
    };
  };

  d = dists.${system} or (throw "Unsupported system: ${system}");
in
  python3.pkgs.buildPythonPackage rec {
    pname = "pyrefly";
    version = "0.42.1";
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
