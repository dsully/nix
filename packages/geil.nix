{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "94a709b29a838e04a8716a49c448ebf4e0d788fc";
    pname = "geil";
    version = "0.0.1-alpha.1-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "Nukesor";
      repo = pname;
      hash = "sha256-DtAaesGa0qQGBEbCpJ1DWoFcD7isHRLGEFy3F9ytEGE=";
    };

    cargoHash = "sha256-6rEPWktNDaJ2Ea+UfaxTqP4ZdtmuhxsEa88UgE0Q8Fo=";
    doCheck = false;

    meta = {
      description = "Rocket: A tool to update your repositories and for keeping them clean";
      homepage = "https://github.com/Nukesor/geil";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
