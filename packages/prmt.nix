{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "prmt";
    rev = "9c227f0aeb1080fa3e07e4e1009cbc494cfe8b3f";
    version = "0.1.7-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "3axap4eHko";
      repo = "prmt";
      hash = "sha256-6WbczbokR1UzBvVmxrXTSZ2Pk9bgy6fdTtyY8rN+00Y=";
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
