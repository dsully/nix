{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "23a3b6ef2337c8a2c1496ebf68d12582f0b0706d";
    pname = "ty";
    version = "0.0.1a11-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "astral-sh";
      repo = "ruff";
      hash = "sha256-sjbVn3NHaI20f0p0Ra8FRCm3lNGr+LtU0KN5nyFEBUE=";
    };

    cargoBuildFlags = ["--package=ty"];
    cargoHash = "sha256-pZ591mN661oRSCuy+6r3kL0z0vgYDnXJV2xyLtwkNXg=";

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
