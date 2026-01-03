{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "0211db7c7f718e6f87f5623883d0eff0464caf34";
    pname = "geil";
    version = "0.0.1-alpha.1-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "Nukesor";
      repo = pname;
      hash = "sha256-E0+qgorCMbQ9wNuutCe3EdmUu8GWwWyITWn+xm5ztag=";
    };

    cargoHash = "sha256-K5yt6rlWTxe5F3C1H+VSzpsNsduACCzSLfFiOWQDgxI=";
    doCheck = false;

    meta = {
      description = "Rocket: A tool to update your repositories and for keeping them clean";
      homepage = "https://github.com/Nukesor/geil";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
