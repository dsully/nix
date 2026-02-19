{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "af5592327219199c263df8450e0f57c3e6080949";
    pname = "geil";
    version = "0.0.1-alpha.1-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "Nukesor";
      repo = pname;
      hash = "sha256-Qg+2S0dcEHGfSyvb/YDkno8lCMss9pEgpwY1Y03Jh1A=";
    };

    cargoHash = "sha256-jFVxuFjFO6J1e92FLJ+/fih/9V48nnUvIvFFjLMIbQA=";
    doCheck = false;

    meta = {
      description = "Rocket: A tool to update your repositories and for keeping them clean";
      homepage = "https://github.com/Nukesor/geil";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
