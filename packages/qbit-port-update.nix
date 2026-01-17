{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "qbit-port-update";

    rev = "3043e88c53005390ffad5e7b65c18b6284b5a702";
    version = "0.0.1-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "dsully";
      repo = "qbit-port-update";
      hash = "sha256-HpX6Icy/5sPYGZOUP0H/arV7ay6k/9LXQVGA2B3qWQE=";
    };

    cargoHash = "sha256-DNijask9UcPSYXdLixKmFDqexsJuxhf2D4gZyfy8714=";
    doCheck = false;

    nativeBuildInputs = lib.optionals stdenv.isLinux [
      pkg-config
    ];

    buildInputs = lib.optionals stdenv.isLinux [
      openssl
    ];

    meta = {
      description = "QB Tools";
      homepage = "https://github.com/dsully/qbit-port-update.git";
      mainProgram = pname;
    };
  }
