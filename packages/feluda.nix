{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "feluda";
    version = "1.9.7";

    src = fetchFromGitHub {
      owner = "anistark";
      repo = pname;
      rev = "1091ef1e5fa107b2ee10f5e249a1afab0a6b99b4";
      hash = "sha256-EmdgKcOm2tM8xqTWsvnni7Ku5gwvUQUWNqQK6hADZ6U=";
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
