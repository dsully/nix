{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "feluda";
    version = "1.9.2";

    src = fetchFromGitHub {
      owner = "anistark";
      repo = pname;
      rev = "90c46cfc14708e3c86b65451805d491802ac1adc";
      hash = "sha256-FSqSaCp6mmnXtGLrwzJUS4b0fB8yMMsrD/qpI3w7HJI=";
    };

    useFetchCargoVendor = true;
    cargoHash = "sha256-UmuCSuy02G3QDP6XDr/w2jTHIhIj95WWyCts1w0NDYY=";
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
