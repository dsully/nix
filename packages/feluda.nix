{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage {
    pname = "feluda";
    version = "1.9.0";

    src = fetchFromGitHub {
      owner = "anistark";
      repo = "feluda";
      rev = "cb0214e22999cbee8406035ff02d45651a31d266";
      hash = "sha256-+zEDfqX6DybtqEtci6jX6xyLx2CQAEPWSlWaE99RDHI=";
    };

    useFetchCargoVendor = true;
    cargoHash = "sha256-iQN0e3Age9+QnudoCxBl2FU82bBYi22LJGZbQnnlt+4=";
    doCheck = false;

    nativeBuildInputs = [
      pkg-config
    ];

    buildInputs = [
      openssl
    ];

    meta = {
      description = "Detect license usage restrictions in your project";
      homepage = "https://github.com/anistark/feluda";
      license = lib.licenses.mit;
      mainProgram = "feluda";
    };
  }
