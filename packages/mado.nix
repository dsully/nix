{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "mado";
    rev = "859ab97959fd8491c8b674e0858bf136a0a9c1b5";
    version = "0.3.0-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "akiomik";
      repo = pname;
      hash = "sha256-HWogx02aw7D1+uLEGmV3VGDBRclQC9/uLRa6eWiMYE8=";
    };

    cargoHash = "sha256-zohG9pNiURVlY1TkFln76NcCvGqicyE+c9lXTPO1SfE=";
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
