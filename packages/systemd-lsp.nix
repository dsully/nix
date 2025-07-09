{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "systemd-lsp";
    version = "0.1.0";

    src = fetchFromGitHub {
      owner = "JFryy";
      repo = pname;
      rev = "735b3b238740f3d4b5236c8b51695a3bd2eff258";
      hash = "sha256-onQemuqAFZvx2ZWDs+9F7Niac9+YiTvFYEZhJd0K/UY=";
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
