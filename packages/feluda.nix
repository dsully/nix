{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "feluda";
    rev = "cf800378f93ba401da384f36dd8722d4d5472ced";
    version = "1.9.8-rc1-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "anistark";
      repo = pname;
      hash = "sha256-HKIXq0RGpoSFU6DmGUUd41FDr9KRxaKYXemdoX1VrpY=";
    };

    cargoHash = "sha256-HoLqbogtlTkvc8KzlY8Ha/8wYIAIhdze7lgECBcEk2U=";
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
