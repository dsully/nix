{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage {
    pname = "feluda";
    version = "1.7.0";

    src = fetchFromGitHub {
      owner = "anistark";
      repo = "feluda";
      rev = "73953e4babf83ae11b8ba11a32019d89e811d747";
      hash = "sha256-rx+VZuA896TNlacIhMMMMhjz3L2BZouiY6HNYCm6nK8=";
    };

    useFetchCargoVendor = true;
    cargoHash = "sha256-JXDd2EB2ew9f+EvK76nkV0eBC4gshpo1eXWvRb2PHgs=";
    doCheck = false;

    nativeBuildInputs = [
      pkgs.pkg-config
    ];

    buildInputs = [
      pkgs.openssl
    ];

    meta = {
      description = "Detect license usage restrictions in your project";
      homepage = "https://github.com/anistark/feluda";
      license = lib.licenses.mit;
      mainProgram = "feluda";
    };
  }
