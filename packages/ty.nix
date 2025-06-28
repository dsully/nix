{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "90cb0d3a7b0d1b9528854dad64dd17330bfd5f36";
    pname = "ty";
    version = "0.12.1";

    src = fetchFromGitHub {
      inherit rev;
      owner = "astral-sh";
      repo = "ruff";
      hash = "sha256-voV5iqRDDVn0ptx6JoxdoGy19UaVPnsAlWlt5AU3bRs=";
    };

    cargoBuildFlags = ["--package=ty"];
    cargoHash = "sha256-rt/AwzICsF9OBeTaehAuSQd+t6C8vGMB7I1WPECtl5k=";

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
