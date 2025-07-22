{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "dc10ab81bd85b8af49ee2fe8ed4a6f767d37d6e0";
    pname = "ty";
    version = "0.0.1a15-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "astral-sh";
      repo = "ruff";
      hash = "sha256-aXxHI352nmnesqtxBdMNn8c6GXvgTMa+6UqH1qitBF8=";
    };

    cargoBuildFlags = ["--package=ty"];
    cargoHash = "sha256-kKU5x7Ahx69hGMwidf/2Ul183lesMrqDEk9nee1Mo9Y=";

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
