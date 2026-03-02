{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "5fa60e5143b1f4eaa7258d4e269457ede31c9314";
    pname = "geil";
    version = "0.0.1-alpha.1-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "Nukesor";
      repo = pname;
      hash = "sha256-7JnBcTFHG1cMMBcixZ9zCskv6mXIb4xhdg1ci3pQ++k=";
    };

    cargoHash = "sha256-H77UKRcUFIPf6CUSjQmP0UIurWnXgPprq+u9/Fwcao8=";
    doCheck = false;

    meta = {
      description = "Rocket: A tool to update your repositories and for keeping them clean";
      homepage = "https://github.com/Nukesor/geil";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
