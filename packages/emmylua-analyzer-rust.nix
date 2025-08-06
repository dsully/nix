{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "349ecfba046a2339117357378bc292812d727564";
    pname = "emmylua-analyzer-rust";
    version = "0.10.0-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "EmmyLuaLs";
      repo = "emmylua-analyzer-rust";
      hash = "sha256-tb1DFOqtVHt0Mnv2uL3MQ8cX5uK/9sqevqZbIfDTpHo=";
    };

    cargoHash = "sha256-MIGYx1qMxsCCq3QkFeOuKbM4w/sJ2K0T+SRIDJQjf/8=";
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
