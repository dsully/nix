{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "5e02d839d5778a0faae468b196d7b320efdbddbe";
    pname = "ty";
    version = "0.0.1-alpha.10-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "astral-sh";
      repo = "ruff";
      hash = "sha256-n/L/kkORAN9j4RyVdztEkX9N7mKtL+mvYFrXxpZKFUc=";
    };

    cargoBuildFlags = ["--package=ty"];
    cargoHash = "sha256-MLdB1vGLVnylvYj8/asbXq5fy8yw8dbZoi4fytknfR4=";

    doCheck = false;
    nativeBuildInputs = [installShellFiles];
    useFetchCargoVendor = true;

    env.TY_VERSION = version;

    postInstall = lib.optionalString (stdenv.hostPlatform.emulatorAvailable buildPackages) (
      let
        emulator = stdenv.hostPlatform.emulator buildPackages;
      in ''
        installShellCompletion --cmd ty \
          --bash <(${emulator} $out/bin/ty generate-shell-completion bash) \
          --fish <(${emulator} $out/bin/ty generate-shell-completion fish) \
          --zsh <(${emulator} $out/bin/ty generate-shell-completion zsh)
      ''
    );

    passthru = {
      updateScript = nix-update-script {extraArgs = ["--version=unstable"];};
    };

    meta = {
      description = "Extremely fast Python type checker and language server, written in Rust";
      homepage = "https://github.com/astral-sh/ruff";
      changelog = "https://github.com/astral-sh/ty/blob/${version}/CHANGELOG.md";
      license = lib.licenses.mit;
      inherit version;
      mainProgram = pname;
    };
  }
