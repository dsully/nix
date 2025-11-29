{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "ty";
    rev = "ecab623fb2fe3846de4cafa0dfef0385a7245941";
    version = "0.0.1a28-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "astral-sh";
      repo = "ruff";
      hash = "sha256-7ZgA5e2Cd2xb/jlo0CrEJYKWAAsvyml2KBnhHRimduo=";
    };

    cargoBuildFlags = ["--package=ty"];
    cargoHash = "sha256-2RXFT3ERzw1VpwGnLrS8bsrx4B5xLU6yQkwXAQuR/iM=";
    doCheck = false;
    nativeBuildInputs = [installShellFiles];

    env.TY_VERSION = version;

    postInstall = lib.optionalString (stdenv.hostPlatform.emulatorAvailable buildPackages) (
      let
        emulator = stdenv.hostPlatform.emulator buildPackages;
      in ''
        installShellCompletion --cmd ${pname} \
          --bash <(${emulator} $out/bin/${pname} generate-shell-completion bash) \
          --fish <(${emulator} $out/bin/${pname} generate-shell-completion fish) \
          --zsh <(${emulator} $out/bin/${pname} generate-shell-completion zsh)
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
