{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "magic-opener";
    version = "1237b3a1";

    src = fetchFromGitHub {
      owner = "dsully";
      repo = pname;
      rev = "1237b3a1c306b6af9abb99ed0d122b36323f4604";
      hash = "sha256-AgFuWBmLrR4JlgmtQLavJzm/uH6wP6wvcRGvlRYSlhA=";
    };

    cargoHash = "sha256-wbNA041iji3udJhppOXekmgZJAefV3JIGyPRSDDcyl4=";

    meta = {
      description = "A tool for opening the right thing in the right place";
      homepage = "https://github.com/dsully/magic-opener";
      license = lib.licenses.mit;
      mainProgram = "open";
    };
  }
