{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "ty";
    rev = "ec5584219e7c3863d68c473964de4c649ce5aedf";
    version = "0.0.1a19-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "astral-sh";
      repo = "ruff";
      hash = "sha256-y3xuaBBrQVjc8tBL51mA9+KF14IFGzdgwdvUtAgAB7M=";
    };

    cargoBuildFlags = ["--package=ty"];
    cargoHash = "sha256-R416MUg5kuib7Yq6EADsgdkeFr0XYZ+bOfvEcs75E+E=";

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
