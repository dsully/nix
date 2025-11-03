{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "anthropic-api-key";
    version = "0.1.1";

    src = builtins.fetchGit {
      url = "git@github.com:dsully/anthropic-api-key.git";
      rev = "832230dfff0f46cd39e3166b516c3868c40a9bf5";
    };

    cargoHash = "sha256-Aa4jppD9SS7x6xbbZmXZFJvJQeA8oRHSGc3IpDSNTMA=";

    meta = {
      description = "Generate an Anthropic OAuth Key";
      homepage = "https://github.com/dsully/anthropic-api-key";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
