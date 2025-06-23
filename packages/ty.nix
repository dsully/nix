{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "b64307f65ef9fc5029ecd8b22f51adae18eaaed9";
    pname = "ty";
    version = "0.0.1a11-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "astral-sh";
      repo = "ruff";
      hash = "sha256-lfR7J7FikzkFV2GU0/3Pii/zgSKJffpb+eah+WXD7W8=";
    };

    cargoBuildFlags = ["--package=ty"];
    cargoHash = "sha256-m2eh6ep3+vc69NjRyGCngbuVx29vpZCGG4apc0dkGYs=";

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
