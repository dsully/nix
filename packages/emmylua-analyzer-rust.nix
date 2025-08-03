{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "9464063492bd577b8fdbf9f985bde64928278aee";
    pname = "emmylua-analyzer-rust";
    version = "0.10.0-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "EmmyLuaLs";
      repo = "emmylua-analyzer-rust";
      hash = "sha256-edOrPKX4L/Sipp0CWmqi61qoK0nJm0B0t4m7488rha8=";
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
