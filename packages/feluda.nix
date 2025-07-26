{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "feluda";
    version = "1.9.2";

    src = fetchFromGitHub {
      owner = "anistark";
      repo = pname;
      rev = "dcfba8c319052123e992987913fa987f6d9ecb12";
      hash = "sha256-CcXM4tCBByLt7NdbSb12LAc5TaICix0zBawTjSWivYs=";
    };

    useFetchCargoVendor = true;
    cargoHash = "sha256-Iip+7f7YTXrtzn8lMp5qbrZ1UQQWzpi2ohbL3IgU6K8=";
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
