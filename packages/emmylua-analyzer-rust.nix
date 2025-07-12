{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "428906297ce131e375b080150cc2efd4d263f5d7";
    pname = "emmylua-analyzer-rust";
    version = "0.9.0-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "EmmyLuaLs";
      repo = "emmylua-analyzer-rust";
      hash = "sha256-JGUaG8ukoJaYsp7vRCYezsmnRiKnC0qSjT31shudykg=";
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
