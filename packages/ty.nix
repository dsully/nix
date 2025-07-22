{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "6d4687c9af5122ece221699e0b1553722710d5aa";
    pname = "ty";
    version = "0.0.1a15-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "astral-sh";
      repo = "ruff";
      hash = "sha256-6vTvZ0IfQ4pRTk+pub9P0ernP0Q8RP7mIueyxVmt9Ew=";
    };

    cargoBuildFlags = ["--package=ty"];
    cargoHash = "sha256-XOyWUN8ywCqcYPC1wAC4dYkjbZdBnAoHeUXceVXf9GY=";

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
