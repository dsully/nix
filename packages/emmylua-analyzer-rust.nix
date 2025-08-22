{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "e4b6e7c9f9806e1405e89a9e7c769fb5b96f76b4";
    pname = "emmylua-analyzer-rust";
    version = "0.10.0-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "EmmyLuaLs";
      repo = "emmylua-analyzer-rust";
      hash = "sha256-IXoiXfRnGOZQ7c8AJaK8OGjqp1bczd/tKjtpbYdCZlU=";
    };

    cargoHash = "sha256-7QQipbnqelLdzQr+lIORyQNM9SS5yHaJLQ31M52lYCw=";
    doCheck = false;

    nativeBuildInputs = [
      pkg-config
    ];

    meta = {
      description = "";
      homepage = "https://github.com/EmmyLuaLs/emmylua-analyzer-rust/";
      changelog = "https://github.com/EmmyLuaLs/emmylua-analyzer-rust/blob/${src.rev}/CHANGELOG.md";
      license = lib.licenses.mit;
      mainProgram = "emmylua_ls";
    };
  }
