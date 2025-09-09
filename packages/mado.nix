{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "mado";
    rev = "df0264a9807970ea24b12a2f6610e3821b4efba5";
    version = "0.3.0-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "akiomik";
      repo = pname;
      hash = "sha256-h1eFbt26vDbisZwP80RpyLYF1MeaEJ4u71H2pSbsboc=";
    };

    cargoHash = "sha256-uoqzmQK2EQPcIP1332OMQov6Yb0ZQOYEfemzFS/JeXM=";
    doCheck = false;

    nativeBuildInputs = [
      installShellFiles
      pkg-config
    ];

    buildInputs = [
      oniguruma
      rust-jemalloc-sys
    ];

    env = {
      RUSTONIG_SYSTEM_LIBONIG = true;
    };

    postInstall = lib.optionalString (stdenv.hostPlatform.emulatorAvailable buildPackages) (
      let
        emulator = stdenv.hostPlatform.emulator buildPackages;
      in ''
        installShellCompletion --cmd mado \
          --bash <(${emulator} $out/bin/mado generate-shell-completion bash) \
          --fish <(${emulator} $out/bin/mado generate-shell-completion fish) \
          --zsh <(${emulator} $out/bin/mado generate-shell-completion zsh)
      ''
    );

    meta = {
      description = "A fast Markdown linter written in Rust";
      homepage = "https://github.com/akiomik/mado";
      changelog = "https://github.com/akiomik/mado/blob/${src.rev}/CHANGELOG.md";
      license = lib.licenses.asl20;
      mainProgram = pname;
    };
  }
