{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "feluda";
    rev = "3a7bb45c10f0894543d73d7d0f7faaefdd3fae78";
    version = "1.9.8-rc1-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "anistark";
      repo = pname;
      hash = "sha256-Y8aFww18oFbwLkK7tYDJlI2sW4vDqT4EE50mHLZiZ1Q=";
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
