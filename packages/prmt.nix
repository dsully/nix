{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "prmt";
    rev = "b71c530d9555750176926945a50897f625700bca";
    version = "0.1.7-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "3axap4eHko";
      repo = "prmt";
      hash = "sha256-R82ZXh9zuz901J9Ut5Y4dtfl/etCDX/IXmnHMKWbNQ8=";
    };

    cargoHash = "sha256-+2JMBGEx+dChXfpOQOKjZk5VZAtAFOTtIojLZ7+w9I0=";
    doCheck = false;

    meta = {
      description = "Ultra-fast, customizable shell prompt generator";
      homepage = "https://github.com/3axap4eHko/prmt";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
