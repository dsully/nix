{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "feluda";
    rev = "833bf4b5f0b16bff0bf6d6bdf6ea9c76aef81b85";
    version = "1.9.8-rc1-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "anistark";
      repo = pname;
      hash = "sha256-9QE6Fp5t5ussQcfZxw8D6UoFXjaBDyc09gDhC9wK48E=";
    };

    cargoHash = "sha256-m2KcjFKU13gUJnShaTbTHgn9gwXV1FioCM7W+8o9VMM=";
    doCheck = false;

    nativeBuildInputs = [
      perl
      pkg-config
    ];

    meta = {
      description = "Detect license usage restrictions in your project";
      homepage = "https://github.com/anistark/feluda";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
