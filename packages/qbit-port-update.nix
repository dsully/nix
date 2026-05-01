{
  lib,
  rustPlatform,
  pkg-config,
  openssl,
  stdenv,
  emptyFile,
  ...
}:
if stdenv.hostPlatform.isLinux
then
  rustPlatform.buildRustPackage rec {
    pname = "qbit-port-update";
    version = "0.0.1";

    src = fetchGit {
      url = "git+ssh://git@github.com/dsully/qbit-port-update";
      rev = "3043e88c53005390ffad5e7b65c18b6284b5a702";
    };

    cargoHash = "sha256-DNijask9UcPSYXdLixKmFDqexsJuxhf2D4gZyfy8714=";
    doCheck = false;

    nativeBuildInputs = [
      pkg-config
    ];

    buildInputs = [
      openssl
    ];

    meta = {
      description = "QB Tools";
      homepage = "https://github.com/dsully/qbit-port-update.git";
      mainProgram = pname;
      platforms = lib.platforms.linux;
    };
  }
else emptyFile
