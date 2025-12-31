{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "magic-opener";
    version = "65c6232e";
    rev = "65c6232e14fb8dbec140978756c4cf6bda131f5e";

    src = fetchFromGitHub {
      inherit rev;
      owner = "dsully";
      repo = pname;
      hash = "sha256-JwORx3LV6WryyoDPL9ldFbNwpkQqotWJHWBPkm5A1dc=";
    };

    cargoHash = "sha256-o3Tg+PEARnYEfvBFuIqiB6AbixTW3m6WffrskcsvSH4=";

    meta = {
      description = "A tool for opening the right thing in the right place";
      homepage = "https://github.com/dsully/magic-opener";
      license = lib.licenses.mit;
      mainProgram = "open";
    };
  }
