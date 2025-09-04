{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "daaf9433ba6af9a3b95208402ac8c95410f9d258";
    pname = "geil";
    version = "0.0.1-alpha.1-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "Nukesor";
      repo = pname;
      hash = "sha256-+gnLD8owyB2aBow9JG8xSY2qPAVPwb2UnnZw2F17CpU=";
    };

    cargoHash = "sha256-mrSEIIsheuPbsCd/Sbk1n7Fq8HQX4JECeAiktgVIzBc=";
    doCheck = false;

    meta = {
      description = "Rocket: A tool to update your repositories and for keeping them clean";
      homepage = "https://github.com/Nukesor/geil";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
