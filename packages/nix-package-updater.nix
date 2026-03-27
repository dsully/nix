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
  version = "0.5.3";

  src = fetchFromGitHub {
    owner = "dsully";
    repo = pname;
    rev = "10164d574ad7f2e0088b3b8bd70fe0cb80c33de7";
    hash = "sha256-AfjIMZf8Qm6TnAoWXW8r2Rv5zrfESM3pLKBrPi/Y578=";
  };

  cargoHash = "sha256-IC1SSPaHhofVvGoNpfcN+jrMpfT13gp82j049N0slVo=";

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
