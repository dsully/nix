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
  version = "0.5.9";

  src = fetchFromGitHub {
    owner = "dsully";
    repo = pname;
    rev = "ae5009582f3fa5f5a970f621b052cbd0b4fc1252";
    hash = "sha256-yMarGddBKXy1Mktyny2jmLYQrF/d8d3xW0KLy/TF7YU=";
  };

  cargoHash = "sha256-EaJYqyUy/w6cOIOj72As/ZSuKOG2bWpAdPg5Fhx4FmU=";

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
