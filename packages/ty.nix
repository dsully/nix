{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "905b9d7f515ff4b093a9a55997e1855b54e2d73a";
    pname = "ty";
    version = "0.0.1a15-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "astral-sh";
      repo = "ruff";
      hash = "sha256-6cmdj73J3fuH4YeiU2H5wk0omIAkW1FiuZ9wL4fAzG8=";
    };

    cargoBuildFlags = ["--package=ty"];
    cargoHash = "sha256-ukDdN72kHyJuRK/uJVgY8voiUp8eZZOizTyANGz4l4s=";

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
