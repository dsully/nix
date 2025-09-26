{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "mado";
    rev = "d49924383c91ac9dda8de57cf8d141d903fdf4f7";
    version = "0.3.0-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "akiomik";
      repo = pname;
      hash = "sha256-ihWDISDSJ0XL3ObGZj78qtBs8CeMQCrnlkZ72W80fR0=";
    };

    cargoHash = "sha256-6jqU2jsPGgDKsSrT9kx0n/5EvKv7kfNuxnthlbICyko=";
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
