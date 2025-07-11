{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "systemd-lsp";
    version = "0.1.0";

    src = fetchFromGitHub {
      owner = "JFryy";
      repo = pname;
      rev = "d59bffa9ff1f2c762a67cc0eb7a59134369d8940";
      hash = "sha256-JjrPgpQ94C01nZ3E1NE88TBzI03YFs+x37edtYStlnc=";
    };

    cargoHash = "sha256-G1cQWOgtx+Bmi05ji9Z4TBj5pnhglNcfLRoq2zSmyK0=";
    useFetchCargoVendor = true;
    doCheck = false;

    meta = {
      description = "A language server implementation for systemd unit files made in rust";
      homepage = "https://github.com/JFryy/systemd-lsp";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
