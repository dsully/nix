{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "7b4103bcb63350505e3d6df77367325c543ad0f9";
    pname = "ty";
    version = "0.0.1a16-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "astral-sh";
      repo = "ruff";
      hash = "sha256-PW0TJhcOzURt+7BGRpfqdzEA3mcqzzuXu6GFCMeNB2o=";
    };

    cargoBuildFlags = ["--package=ty"];
    cargoHash = "sha256-gn0K1c6yecGUZXwFBetH+dMD+2C48PyWmkSTzldYN8E=";

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
