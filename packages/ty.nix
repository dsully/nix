{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "4d8ccb612557f8b35bd19b69ad6e0a073510e69c";
    pname = "ty";
    version = "0.0.1a17-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "astral-sh";
      repo = "ruff";
      hash = "sha256-CxIlZ8QEfnXDc+Yy5ihq6nJ3zSbMjK+zRlbUTfU854M=";
    };

    cargoBuildFlags = ["--package=ty"];
    cargoHash = "sha256-OCI9W0e9uiCPV9V06VXlc8yeEbTgzPV5iSTnEE9BohI=";

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
