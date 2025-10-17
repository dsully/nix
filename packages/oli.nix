{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "oli";
    version = "12944ade";

    src = fetchFromGitHub {
      owner = "amrit110";
      repo = pname;
      rev = "12944adebffef7e025362d10f9eadf62b03cda79";
      hash = "sha256-nF6lllM69ERulBCyBbxr8NZHZh0SAqnV/pPe14xvvIU=";
    };

    cargoHash = "sha256-6jTYD2Bc7q+nrgaS7HXM6gG53hMCYyuzpobWcRCvBgw=";
    doCheck = false;

    nativeBuildInputs = [
      pkgs.pkg-config
    ];

    buildInputs = [
      pkgs.openssl
    ];

    meta = {
      description = "A simple, fast terminal based AI coding assistant";
      homepage = "https://github.com/amrit110/oli";
      license = lib.licenses.asl20;
      mainProgram = pname;
    };
  }
