{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "feluda";
    rev = "54c41c21bc6903bb8f65a8b4038b294fada31e55";
    version = "1.9.8-rc1-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "anistark";
      repo = pname;
      hash = "sha256-4T/Hykqzoi9h22CxVb2XSi89koPp9edRoPuz8qCEw8s=";
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
