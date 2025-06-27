{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage {
    pname = "njq";
    version = "0.1.0";

    src = fetchFromGitHub {
      owner = "Rucadi";
      repo = pname;
      rev = "fdf802c36bce38629a47af06f33b8376aeff46e8";
      hash = "sha256-AQlAeGS3WHf2Ke7Fk5v5DtiCrLfhtmX0E1eStGiALsc=";
    };

    cargoHash = "sha256-tDz9+iQhutlo7petKmg6n/mg0tDntGRqwBALcATJwdM=";
    useFetchCargoVendor = true;

    meta = {
      description = "Command-line JSON processor using nix as query language";
      homepage = "https://github.com/Rucadi/njq";
      license = lib.licenses.mit;
      maintainers = with lib.maintainers; [dsully];
      mainProgram = pname;
    };
  }
