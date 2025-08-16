{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "ty";
    rev = "9ac39cee98d568c712f3849cc816265488119989";
    version = "0.0.1a18-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "astral-sh";
      repo = "ruff";
      hash = "sha256-GBtdGtw+C/YAKusSANyvMnLIVjKq5EGo3H8aZrrtTac=";
    };

    cargoBuildFlags = ["--package=ty"];
    cargoHash = "sha256-gXuRcb1Gk5t2R44/xeE+x3AXccnRyt9SukYYXE0JPQU=";

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
