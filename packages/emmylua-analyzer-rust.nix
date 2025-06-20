{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "emmylua-analyzer-rust";
    version = "0.8.1";

    src = fetchFromGitHub {
      owner = "EmmyLuaLs";
      repo = "emmylua-analyzer-rust";
      rev = version;
      hash = "sha256-6ltnF1xmGc5OmhWNFmTKzVrOWjsMbeqg55dqfJIIHZI=";
    };

    cargoHash = "sha256-a2dA4NP847Km4ycfPssNjJyP58eHWdfSxUgaKPFHcIE=";
    useFetchCargoVendor = true;
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
