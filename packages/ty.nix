{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "ty";
    rev = "bc89d0394ca2ee3161df37b8fa3de307d001e54f";
    version = "0.0.1a20-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "astral-sh";
      repo = "ruff";
      hash = "sha256-D/fQkGmrtcVabrNk+Qou3WS9DEZIfyX/e32pNX0GXQk=";
    };

    cargoBuildFlags = ["--package=ty"];
    cargoHash = "sha256-WtRryq8bmKfL3EL2kRFFokmG2f0lnS6zRMbUzGeYLDM=";

    doCheck = false;
    nativeBuildInputs = [installShellFiles];

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
