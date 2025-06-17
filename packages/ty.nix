{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "913f136d33fbc1b7d20fc91190431ccef2e2834c";
    pname = "ty";
    version = "0.0.1-alpha.10-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "astral-sh";
      repo = "ruff";
      hash = "sha256-uZGktqf9m5QFt72gR45iiaNnC6/R6EelSFohFUiajLM=";
    };

    cargoBuildFlags = ["--package=ty"];
    cargoHash = "sha256-mtUnb2AXsnmooDg+0HkCGjybWsRoKkdypVOVyM6D6qs=";

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
