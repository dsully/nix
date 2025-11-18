{pkgs, ...}:
with pkgs; let
  dists = {
    aarch64-darwin = {
      platform = "macosx_11_0_arm64";
      hash = "sha256-OG7zrZ8j1RSLDP/AQ96v2krDH6SSCwzpfE7NYLpChoc=";
    };
    x86_64-linux = {
      platform = "manylinux_2_17_x86_64.manylinux2014_x86_64";
      hash = "sha256-DscgGpvjIUzXNPlMRGi1B3eEX+AliHzv3ZfmZuluAyo=";
    };
  };

  d = dists.${system} or (throw "Unsupported system: ${system}");
in
  python3.pkgs.buildPythonPackage rec {
    pname = "rumdl";
    version = "0.0.178";
    format = "wheel";

    src = fetchPypi {
      inherit pname version format;
      inherit (d) hash platform;
      abi = "none";
      python = "py3";
      dist = "py3";
    };

    meta = {
      description = "A fast Markdown linter written in Rust";
      homepage = "https://pypi.org/project/rumdl";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
