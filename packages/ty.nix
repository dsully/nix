{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "f4d027353232b1a723430ffa9bc22ceb213f175b";
    pname = "ty";
    version = "0.0.1a14-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "astral-sh";
      repo = "ruff";
      hash = "sha256-Ee9LtezTxmUEpn185cNmIDgcwOUsqgwBUH5N6przvd8=";
    };

    cargoBuildFlags = ["--package=ty"];
    cargoHash = "sha256-onduyy6T5cz8zbMGrnNyfB5SuLTeluyg7wjLnvLaRRY=";

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
