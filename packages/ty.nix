{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "6bc52f285544c42a973b3bd97eaa53615ea3c022";
    pname = "ty";
    version = "0.0.1a17-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "astral-sh";
      repo = "ruff";
      hash = "sha256-aOvhn8qg3iz5L6SyhLTs20YrJGdUCp9SW+/+SqEYj5A=";
    };

    cargoBuildFlags = ["--package=ty"];
    cargoHash = "sha256-njRzRgGT5sZNB3kccq8Qrlufd7ZsEHbkwKW6D8VsdWE=";

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
