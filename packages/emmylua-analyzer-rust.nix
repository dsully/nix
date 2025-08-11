{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "c5a35063685395ae3bf147371c7340a41da53ac9";
    pname = "emmylua-analyzer-rust";
    version = "0.10.0-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "EmmyLuaLs";
      repo = "emmylua-analyzer-rust";
      hash = "sha256-9xSAm5AnzhNkfc0Jgo++H72XTM6lIKesHFeZcORGE2g=";
    };

    cargoHash = "sha256-3x71VNWCTFb75STx8w/T++dLo1s2FwNhFm+lyZHS7qI=";
    doCheck = false;

    nativeBuildInputs = [
      pkg-config
    ];

    meta = {
      description = "";
      homepage = "https://github.com/EmmyLuaLs/emmylua-analyzer-rust/";
      changelog = "https://github.com/EmmyLuaLs/emmylua-analyzer-rust/blob/${src.rev}/CHANGELOG.md";
      license = lib.licenses.mit;
    };
  }
