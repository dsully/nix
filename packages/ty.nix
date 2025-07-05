{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "08d8819c8a3a9f9d4a303fc62cfc69164e0d4df4";
    pname = "ty";
    version = "0.0.1a13-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "astral-sh";
      repo = "ruff";
      hash = "sha256-wdJrrofkWF9a5YSUNJO+aKDE376nP+5EDWve/vTct/0=";
    };

    cargoBuildFlags = ["--package=ty"];
    cargoHash = "sha256-rjMdF7QXJkZSH4v3QgzZieLtg/cb+5ArpLFn/SUGars=";

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
