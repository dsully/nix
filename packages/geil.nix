{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "4fee60e04cbc39fd1bb6c49e230131b737c6c71b";
    pname = "geil";
    version = "0.0.1-alpha.1-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "Nukesor";
      repo = pname;
      hash = "sha256-fWaGU4x5lKIKvvkrGEC2+/xUzDDM78lAt5bmgVUtmxA=";
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
