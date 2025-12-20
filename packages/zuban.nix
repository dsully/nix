{pkgs, ...}:
with pkgs; let
  dists = {
    aarch64-darwin = {
      platform = "macosx_11_0_arm64";
      hash = "sha256-hfis8+MjQpeWP7FOykd8pX0CaF/jQfD8UqiOOnXTeWI=";
    };
    x86_64-linux = {
      platform = "manylinux_2_17_x86_64.manylinux2014_x86_64";
      hash = "sha256-oSdlq31quz0dCFqWbKwD7WLQIDqht4BVWKe70IkTJ2w=";
    };
  };

  d = dists.${system} or (throw "Unsupported system: ${system}");
in
  python3.pkgs.buildPythonPackage rec {
    pname = "zuban";
    version = "0.4.0";
    format = "wheel";

    src = fetchPypi {
      inherit pname version format;
      inherit (d) hash platform;
      abi = "none";
      python = "py3";
      dist = "py3";
    };

    meta = {
      description = "A Mypy-compatible Python Language Server built in Rust";
      homepage = "https://pypi.org/project/zuban/";
      mainProgram = pname;
    };
  }
