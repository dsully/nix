{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "27862271d5598bd1b2cbb8ca7054ca0160dc499d";
    pname = "geil";
    version = "0.0.1-alpha.1-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "Nukesor";
      repo = pname;
      hash = "sha256-WyyxELLcYhn90FAVwiucZRvc8OOHc3eBfjFDsvNtjn4=";
    };

    cargoHash = "sha256-Npvq/WwCmKaJzdImQsxm9QmugR89TI6CFmjsPBK7zO8=";
    doCheck = false;

    meta = {
      description = "Rocket: A tool to update your repositories and for keeping them clean";
      homepage = "https://github.com/Nukesor/geil";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
