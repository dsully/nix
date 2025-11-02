{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "93647ef65fe5afa60b7ca54be05a84ea7c984169";
    pname = "geil";
    version = "0.0.1-alpha.1-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "Nukesor";
      repo = pname;
      hash = "sha256-IyW+/WgWtMMjHRWtbIHfBjLaswt/YptvVyQpmYfQjM0=";
    };

    cargoHash = "sha256-pK30jtkGtZbY5U6w7+0bJibUAyoolTZQv0cGEQJLAa4=";
    doCheck = false;

    meta = {
      description = "Rocket: A tool to update your repositories and for keeping them clean";
      homepage = "https://github.com/Nukesor/geil";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
