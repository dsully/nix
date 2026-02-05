{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "devmoji-log";
    version = "0.0.2";

    src = fetchFromGitHub {
      owner = "dsully";
      repo = pname;
      rev = "beba18c74e5f5449d387a248f5ed4abd8c28192f";
      hash = "sha256-2JDhMIyCRZSyk6UhpmeN8lF2pOS/FhbULFQT9z/nlF4=";
    };

    cargoHash = "sha256-Yz1GW0h3Q+8loqV06xKYRkB3uXWUTPWuRCS5PZ0UH+I=";

    nativeBuildInputs = [
      pkg-config
    ];

    buildInputs = [
      libgit2
      zlib
    ];

    meta = {
      description = "Display Git commit history with conventional commit types and gitmojis";
      homepage = "https://github.com/dsully/devmoji-log";
      license = lib.licenses.mit;
      maintainers = ["dsully"];
      mainProgram = pname;
    };
  }
