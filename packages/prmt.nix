{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "prmt";
    rev = "ee89c33d6d7c8292fbe76bdb9938d8fda9bdf112";
    version = "0.1.7-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "3axap4eHko";
      repo = "prmt";
      hash = "sha256-K7dBG9X+xxBavCUurJwQB7eQwApdoSpVs/TAvwYFSpQ=";
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
