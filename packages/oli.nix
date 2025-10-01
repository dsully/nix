{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "oli";
    version = "c0caefbc";

    src = fetchFromGitHub {
      owner = "amrit110";
      repo = pname;
      rev = "c0caefbcab65b02992314f9e65bbb976480c1103";
      hash = "sha256-AquckkIbCX1vhNI7hsUNtQNjY1erfZfsMhKzK/Rb8Kw=";
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
