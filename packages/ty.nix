{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "ty";
    rev = "e4f1b587cc2a5764e3fd6bda4e48ffedd111f30d";
    version = "0.0.1a18-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "astral-sh";
      repo = "ruff";
      hash = "sha256-TNWJwNAB/OkmQuBFO7mryWoKMYgs/QVsnmtEWCosDfU=";
    };

    cargoBuildFlags = ["--package=ty"];
    cargoHash = "sha256-TNXWRBJInnLiFyf29O8c6ZE7Qhb6sXM0fPRDqMPWSSw=";

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
