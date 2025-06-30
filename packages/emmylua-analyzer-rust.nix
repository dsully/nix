{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "emmylua-analyzer-rust";
    version = "0.8.2";

    src = fetchFromGitHub {
      owner = "EmmyLuaLs";
      repo = "emmylua-analyzer-rust";
      rev = "76b445bcb0f412d5d299a04cbdb28c3e5fbae609";
      hash = "sha256-26IcfWDAe7oJRnsLvj7cpobKT2CmBZtgOm02p2P7xsE=";
    };

    cargoHash = "sha256-6PvMrYC5BGesQ+v0HrKkpXo86QU/VlepRHZxcUMwWAA=";
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
