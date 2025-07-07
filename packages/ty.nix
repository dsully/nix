{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "a6637964d200cc0f1a7a0f89454e4976212d2693";
    pname = "ty";
    version = "0.0.1a13-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "astral-sh";
      repo = "ruff";
      hash = "sha256-jKjFLdP+pnhInTjdQ7p3pBfKmk6CfiJbDfa5dFoMplA=";
    };

    cargoBuildFlags = ["--package=ty"];
    cargoHash = "sha256-ONGmDHpBeueebNsUSvH677QSK2zQFBpBWdp2y8/JW0Y=";

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
