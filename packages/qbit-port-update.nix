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
    version = "0.0.2";

    src = fetchGit {
      url = "git+ssh://git@github.com/dsully/qbit-port-update";
      rev = "7ed90e2d4feca6bcd0d23f8d8699a44801a044c8";
    };

    cargoHash = "";
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
