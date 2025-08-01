{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "06cd249a9be67b8cadc60a1557c2faaf56d7bac7";
    pname = "ty";
    version = "0.0.1a16-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "astral-sh";
      repo = "ruff";
      hash = "sha256-zkkICSuZdeH8ocqH9A/kmvIVvO+9uPLEW3spKS3cK+4=";
    };

    cargoBuildFlags = ["--package=ty"];
    cargoHash = "sha256-tOUbBvOUp1FKtvABB+ptLv639bcqYLbBCCDyDrOkw6o=";

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
