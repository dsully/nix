{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "feluda";
    version = "1.9.2";

    src = fetchFromGitHub {
      owner = "anistark";
      repo = pname;
      rev = "c6b47aff524588079f0a1863dc76934730e71283";
      hash = "sha256-CM3phvSmun0+Uegl8zaiOaWSan5Q8hcM28E2Zck64Dg=";
    };

    useFetchCargoVendor = true;
    cargoHash = "sha256-TKLrtfslNQWb6T+EbumbAa4KdGI3H1gP+GNC0myWiiQ=";
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
      mainProgram = pname;
    };
  }
