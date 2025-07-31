{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "devmoji-log";
    version = "0.0.1";

    src = fetchFromGitHub {
      owner = "dsully";
      repo = pname;
      rev = "59f0b367e424c8aa0a7cb7bea94a46ecf0cfca03";
      hash = "sha256-SwytrsHxowB/DJ1gY257rqILsRrC1iM9FGOwJWA5Nsk=";
    };

    cargoHash = "sha256-f4SCbXOc4F154NvPZB/6SSsUcLeIixLcyNFrO9RVNCs=";

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
