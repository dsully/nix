{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "prmt";
    rev = "b5bcb20649ee55e6b0d75786c90e4a9a2edb078b";
    version = "0.1.7-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "3axap4eHko";
      repo = "prmt";
      hash = "sha256-JS78goKXRxPi7YjVPr8BYL2Rvj8w0ag4YZd6jkQsYHI=";
    };

    cargoHash = "sha256-sx4N8R0WAbS/Atm77eUNLDaevMI58K9O5KzG7FtqmT4=";
    doCheck = false;

    meta = {
      description = "Ultra-fast, customizable shell prompt generator";
      homepage = "https://github.com/3axap4eHko/prmt";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
