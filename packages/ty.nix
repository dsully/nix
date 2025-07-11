{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "39c636454531eb59e4f07e9ac56ac0d803fdb9b7";
    pname = "ty";
    version = "0.0.1a14-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "astral-sh";
      repo = "ruff";
      hash = "sha256-1VqdjqvcTMYJwszS05wmXrBgoUdX+YxifK6KG0F2RxY=";
    };

    cargoBuildFlags = ["--package=ty"];
    cargoHash = "sha256-5fK5VQ+UqkHmPdFz3FKAY9TVjvpePiYifrTHsxnkThM=";

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
