{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "3a542a80f65d66a15e22b6fe161e5af05ddffa83";
    pname = "ty";
    version = "0.0.1a17-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "astral-sh";
      repo = "ruff";
      hash = "sha256-vdpP6T7GrZ8w+aZzN11etUpxeCdilXv3LYGgaOtpm60=";
    };

    cargoBuildFlags = ["--package=ty"];
    cargoHash = "sha256-6FypYeDvpgPagvugRQckLHlbmSdcT/GHG5/mb/44edI=";

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
