{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "352b896c897a0787a5302517c53c6c371aeac8df";
    pname = "ty";
    version = "0.0.1a13";

    src = fetchFromGitHub {
      inherit rev;
      owner = "astral-sh";
      repo = "ruff";
      hash = "sha256-yklZoXD++BfP0GVpGYVOikSHWED0+WDZ4vXZnKuiX7w=";
    };

    cargoBuildFlags = ["--package=ty"];
    cargoHash = "sha256-blf+ISQgOFZ99jZIHQec8Bhccb0ajZiNLvl0F1xUi/Y=";

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
