{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "b964c4e748804b448017c3163bba8ddf71010293";
    pname = "emmylua-analyzer-rust";
    version = "0.12.0-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "EmmyLuaLs";
      repo = "emmylua-analyzer-rust";
      hash = "sha256-kCVTnATCpl67w3KvuFXSyzLXNLppPLfnXb79kuJ9VqI=";
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
