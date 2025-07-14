{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "0658443479281ef78e73329d56324974cf1336eb";
    pname = "emmylua-analyzer-rust";
    version = "0.9.0-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "EmmyLuaLs";
      repo = "emmylua-analyzer-rust";
      hash = "sha256-5fz6vmBbj4gjbjdCTNyJcNWh6SZY6/SNK4UD6/zB3EM=";
    };

    cargoHash = "sha256-H9gb9hv6THoRisGsWc18KWzmF98Fff7MxakKOOKd46c=";
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
