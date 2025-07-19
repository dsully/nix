{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "93a9fabb26e04a489d40df6138e322c3e9c698da";
    pname = "ty";
    version = "0.0.1a15-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "astral-sh";
      repo = "ruff";
      hash = "sha256-Ha5PbdwnAqPCo55gradaTpCgHeHoStV2Z4xQfoGc72I=";
    };

    cargoBuildFlags = ["--package=ty"];
    cargoHash = "sha256-qP53BSsoVDS0GzmwtHWYXi3B0tdsE29ljiTFPlpRQCo=";

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
