{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "geil";
    version = "0.0.1-alpha.1";

    src = fetchFromGitHub {
      owner = "Nukesor";
      repo = pname;
      rev = "d0e9dd8564eb2225e4b96f7954f7ad929a3e82f7";
      hash = "sha256-phGElLly9QrxASwyNAEs6hgreSmFerEfRxcF7MPN1so=";
    };

    cargoHash = "sha256-zBHLQpABduYlgUdchmx8K5V5zRZnl2oPj5ery/SH6pU=";
    useFetchCargoVendor = true;
    doCheck = false;

    meta = {
      description = "Rocket: A tool to update your repositories and for keeping them clean";
      homepage = "https://github.com/Nukesor/geil";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
