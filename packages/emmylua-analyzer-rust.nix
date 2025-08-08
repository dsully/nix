{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "66c58744f5a6bc8844e942d11e878c751af69328";
    pname = "emmylua-analyzer-rust";
    version = "0.10.0-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "EmmyLuaLs";
      repo = "emmylua-analyzer-rust";
      hash = "sha256-Xs/Te6UV8Q8lFYtHiwndN7aSiIFLzNNQUqrt6tLfoGk=";
    };

    cargoHash = "sha256-0XlZaU7Krm1gewDDo2NIfuZqr5QMKmta+k1btGYKJEg=";
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
