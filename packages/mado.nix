{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "mado";
    version = "0.3.0";

    src = fetchFromGitHub {
      owner = "akiomik";
      repo = "mado";
      rev = "59501455c0e870ffb2500ba84e3656b834d845ac";
      hash = "sha256-nG7UkgJm9QcMCsORjQjw+BBJqwsShhhtaRaVwjzWAmg=";
    };

    cargoHash = "sha256-zeldjoH5I4rLXrn145i2WAlg2m7QGIElP0GkmeYjmaU=";
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
      mainProgram = "mado";
    };
  }
