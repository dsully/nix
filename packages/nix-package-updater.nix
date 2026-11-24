{
  lib,
  buildPackages,
  rustPlatform,
  fetchFromGitHub,
  installShellFiles,
  pkg-config,
  libgit2,
  openssl,
  zlib,
  zstd,
  stdenv,
}:
rustPlatform.buildRustPackage rec {
  pname = "nix-package-updater";
  version = "0.7.8";

  src = fetchFromGitHub {
    owner = "dsully";
    repo = pname;
    rev = "8b5f2bae22fe1394f383c9b070f0c840ceab6cfd";
    hash = "sha256-t1EQ9M8VMlZndrV3k0riV7Q/s/L29Ti7h/DTieCwt4I=";
  };

  cargoHash = "sha256-rUkiJkP1GyxwpUKi8jvFn6QKECuSWpdns/69nPX13WQ=";
  doCheck = false;

  nativeBuildInputs = [
    installShellFiles
    pkg-config
  ];

  buildInputs = [
    libgit2
    openssl
    zlib
    zstd
  ];

  postInstall = lib.optionalString (stdenv.hostPlatform.emulatorAvailable buildPackages) (
    let
      emulator = stdenv.hostPlatform.emulator buildPackages;
    in ''
      installShellCompletion --cmd ${pname} \
        --bash <(${emulator} $out/bin/${pname} --completions bash) \
        --fish <(${emulator} $out/bin/${pname} --completions fish) \
        --zsh <(${emulator} $out/bin/${pname} --completions zsh)
    ''
  );

  meta = {
    description = "Update Nix Packages";
    homepage = "https://github.com/dsully/nix-package-updater";
    license = lib.licenses.mit;
    mainProgram = pname;
  };
}
