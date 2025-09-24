{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "feluda";
    rev = "bb1be924adc06c1ce6f9b4f961685b00d0f1744d";
    version = "1.9.8-rc1-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "anistark";
      repo = pname;
      hash = "sha256-JfTcyNlkRZz6iZ+pXWoyKgPz24Oux/QwdvajRAN/BsI=";
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
