{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "feluda";
    rev = "8d7873506df7d9fccb380815f5a21b7915a142c1";
    version = "1.9.8-rc1-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "anistark";
      repo = pname;
      hash = "sha256-xKxqyADfvcPg+pojxHBmDnOeUUy5yCLa/wQwkE1zPVI=";
    };

    cargoHash = "sha256-WDYW4atvqB9frUlCVooQoeHkoak7954N0iyVapgdjpk=";
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
