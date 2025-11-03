{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "anthropic-api-key";
    version = "0.1.1";

    src = pkgs.fetchgit {
      url = "git+ssh://git@github.com/dsully/anthropic-api-key.git";
      hash = "sha256-ib0RK0JkaUKPo0LU1+8XbO36kSEqGFMK+T2yPUcJg+0=";
    };

    cargoHash = "sha256-Aa4jppD9SS7x6xbbZmXZFJvJQeA8oRHSGc3IpDSNTMA=";

    meta = {
      description = "Generate an Anthropic OAuth Key";
      homepage = "https://github.com/dsully/anthropic-api-key";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
