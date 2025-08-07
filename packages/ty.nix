{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "f51a228f04f3f4d0f5444ed739cfffb761f3e0c9";
    pname = "ty";
    version = "0.0.1a17-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "astral-sh";
      repo = "ruff";
      hash = "sha256-ypYtAUQBFSf+cgly9K5eRMegtWrRmLmqrgfRmCJvXEk=";
    };

    cargoBuildFlags = ["--package=ty"];
    cargoHash = "sha256-0iYwS8Ssi4JDxwr0Q2+iKvYHb179L6BiiuXa2D4qiOA=";

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
