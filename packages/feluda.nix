{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "feluda";
    rev = "8913426f1d2f97c6e5b2db67910ce7f8eaf46fb8";
    version = "1.9.8-rc1-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "anistark";
      repo = pname;
      hash = "sha256-yAXTfJs/W2AgW79yjwvbyYYKKq9uCdA5sTuba8ReGGQ=";
    };

    cargoHash = "sha256-SR3eHqtkpfsIXBHqpZ/Hy1d+X3KCNSZreuSOFGLYuxU=";
    doCheck = false;

    nativeBuildInputs = [
      perl
      pkg-config
    ];

    meta = {
      description = "Detect license usage restrictions in your project";
      homepage = "https://github.com/anistark/feluda";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
