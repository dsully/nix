{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "948f3f856cb47c29a556f1fff9ca23b0dd5a1106";
    pname = "ty";
    version = "0.0.1a16-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "astral-sh";
      repo = "ruff";
      hash = "sha256-ZKo2FlClzWmbvMjButviJs2Qdin5JZAjCc7X8mkoKgg=";
    };

    cargoBuildFlags = ["--package=ty"];
    cargoHash = "sha256-21OgKhJypuHVBEzjSehtq7zy+FP7P7mZ/hyW41phR0Y=";

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
