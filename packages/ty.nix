{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "ty";
    rev = "aa63c24b8f4a82f5f54dc90c4e6b5adadbf3e1b2";
    version = "0.0.1a20-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "astral-sh";
      repo = "ruff";
      hash = "sha256-N7MsryKnOU/gIIfOY/Bs1NsMO7GanXzspOnYEP+kUCM=";
    };

    cargoBuildFlags = ["--package=ty"];
    cargoHash = "sha256-4qARO6jmG8DlJMX9X+jjPEfDGN9tAkWbWaYUwBJNCnY=";

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
