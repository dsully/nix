{pkgs, ...}:
with pkgs; let
  dists = {
    aarch64-darwin = {
      platform = "macosx_11_0_arm64";
      hash = "sha256-E7VTCQ7Jghp4EZg4lWS8s8sCBnkYknKx6I/dup1hOHk=";
    };
    x86_64-linux = {
      platform = "manylinux_2_17_x86_64.manylinux2014_x86_64";
      hash = "sha256-b9VfDYZOrWWGB9w75mSQGc+10ccs6wgYtLNQHg64FHI=";
    };
  };

  d = dists.${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
  python3.pkgs.buildPythonPackage rec {
    pname = "pyrefly";
    version = "0.46.3";
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
