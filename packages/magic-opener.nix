{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "magic-opener";
    version = "ca6f4ee2";

    src = fetchFromGitHub {
      owner = "dsully";
      repo = pname;
      rev = "ca6f4ee2bfd8a19fcb10655a73344cc12a112780";
      hash = "sha256-8T2j0yr4Oho2ZKOhmNpiz1hcLkKyuj3jjMqzI8Mn80c=";
    };

    cargoHash = "sha256-wbNA041iji3udJhppOXekmgZJAefV3JIGyPRSDDcyl4=";

    meta = {
      description = "A tool for opening the right thing in the right place";
      homepage = "https://github.com/dsully/magic-opener";
      license = lib.licenses.mit;
      mainProgram = "open";
    };
  }
