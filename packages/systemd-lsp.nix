{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "systemd-lsp";
    version = "0.1.0";

    src = fetchFromGitHub {
      owner = "JFryy";
      repo = pname;
      rev = "f6ed3c80774b3b889f0a14301bff7f058a22f592";
      hash = "sha256-exbAE8iZc8XXBTmXk1oDj8OJHKigGAlxnC4hypr8vss=";
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
