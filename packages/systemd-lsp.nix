{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "systemd-lsp";
    version = "0.1.0";

    src = fetchFromGitHub {
      owner = "JFryy";
      repo = pname;
      rev = "cfb1979edea72ccf89e1b7fed48b6d50335bb9fd";
      hash = "sha256-ODpmrCq8xXOMUHKEjc6Aea3pvv/7tuo55Y0PxY/h/l4=";
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
