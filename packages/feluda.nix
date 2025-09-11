{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "feluda";
    rev = "8341b44a4406ecfc51ebf978a2bc6dd1c4e98cf9";
    version = "1.9.8-rc1-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "anistark";
      repo = pname;
      hash = "sha256-kBaUgsqEs1S90wSGKkhuclf/sgGEysUdqMWIA4tXaQ8=";
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
