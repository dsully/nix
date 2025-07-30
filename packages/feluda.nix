{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "feluda";
    version = "1.9.7";

    src = fetchFromGitHub {
      owner = "anistark";
      repo = pname;
      rev = "0f3874bffdebbfbf226b8a4d39d905bdfc6de46b";
      hash = "sha256-SCDB/JsQh5Ds6VjhoSrsfl1VpMHAgQYsLIEbD3DSffo=";
    };

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
