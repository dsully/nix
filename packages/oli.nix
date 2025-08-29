{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "oli";
    version = "dd228e90";

    src = fetchFromGitHub {
      owner = "amrit110";
      repo = pname;
      rev = "dd228e905b8d45812ac9a250dcfdbc34616b1144";
      hash = "sha256-8tc9yKOZ24v/Qwyap8WxHRPWVpL3kSLSJEftl3Szl88=";
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
