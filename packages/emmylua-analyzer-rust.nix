{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "emmylua-analyzer-rust";
    version = "0.8.2";

    src = fetchFromGitHub {
      owner = "EmmyLuaLs";
      repo = "emmylua-analyzer-rust";
      rev = "2a59703e864e2761f760985b2cd543c9ca6e2828";
      hash = "sha256-J2i4ZakErMcjxC5/yOhSvbQsa9kI+nwi8u0osZCktN0=";
    };

    cargoHash = "sha256-kp1igP/16SUoP2BAOxc4ufxQBmGpK3y/uzBrB6Of0bs=";
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
