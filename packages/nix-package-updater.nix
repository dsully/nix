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
  stdenv,
}:
rustPlatform.buildRustPackage rec {
  pname = "nix-package-updater";
  version = "0.7.4";

  src = fetchFromGitHub {
    owner = "dsully";
    repo = pname;
    rev = "561ab34bd1631c848c7babb6b45d0183cb6beb79";
    hash = "sha256-D1Z/3SbZzT2ZFPpmA3zh1wPOFxw2G/D7uX/9+IHCf88=";
  };

  cargoHash = "sha256-xWYWHZXaQxwGqyxqhfNTw9+46xTlts/lQCh5A8Yis6k=";
  doCheck = false;

  nativeBuildInputs = [
    installShellFiles
    pkg-config
  ];

  buildInputs = [
    libgit2
    openssl
    zlib
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
