{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "cai";
    version = "0.13.0";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-ZrigCzIkv9k2wLzSLfhrJYkzmMpBFx+ym5eNJ1oEMBE=";
    };

    cargoHash = "sha256-dzzDDWDYWtXF8PgMs+7p9iPFeBwxqWFqKZZbnTc9XWM=";
    doCheck = false;

    nativeBuildInputs = [
      pkg-config
    ];

    buildInputs = [
      libgit2
      oniguruma
      openssl
      sqlite
      zlib
    ];

    # env = {
    #   RUSTONIG_SYSTEM_LIBONIG = true;
    # };

    meta = {
      description = "User friendly CLI tool for AI tasks";
      homepage = "https://github.com/ad-si/cai";
      license = lib.licenses.isc;
      mainProgram = pname;
    };
  }
