{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "mado";
    version = "0.3.0";

    src = fetchFromGitHub {
      owner = "akiomik";
      repo = "mado";
      rev = "b0b0ef7fc4db96079b59f10afdd5b62455a0ba8c";
      hash = "sha256-fjXP5s7KionIcSYAcy1tckHoiziSzDOguq3N3VYsoTc=";
    };

    cargoHash = "sha256-h26a6C6Z9thkzZeZkSV3a04lXjhjDcRnCbZoPJb00gg=";
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
