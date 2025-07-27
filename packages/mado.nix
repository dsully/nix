{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "mado";
    version = "0.3.0";

    src = fetchFromGitHub {
      owner = "akiomik";
      repo = pname;
      rev = "dc676712f6e4493d38851f4a5d77b6f00aee2144";
      hash = "sha256-QkYM6LI7iBO3V2/fqlxovzSsLrnfY/mdS5SxCMSFaHo=";
    };

    cargoHash = "sha256-tfi5Dk+UB1RrTr+mREEjcUr6qvAxSBbAGZ3gKlF29kc=";
    useFetchCargoVendor = true;
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
