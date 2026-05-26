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
  version = "0.5.7";

  src = fetchFromGitHub {
    owner = "dsully";
    repo = pname;
    rev = "24611ef1433a7f9c1baa785b5076b23bc89041e2";
    hash = "sha256-1fKMkvtw63jk9mls3RDa899rK6/7Eo0xdzWG63tkBMI=";
  };

  cargoHash = "sha256-Wp8jyWou1Dy5keTCk1scwpSkLfV2FCYpgtuXN1jnK4E=";

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
