{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "2680f2ed8183ae77a4e901b23676ae1abd4bffa5";
    pname = "ty";
    version = "0.0.1a16-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "astral-sh";
      repo = "ruff";
      hash = "sha256-CSyGzEbn7++bwl5O5YHiIjpNPC9RB57MxvpOPp7K7ns=";
    };

    cargoBuildFlags = ["--package=ty"];
    cargoHash = "sha256-njZ/0m9qLAzIyY5w6MHPvpRgHdfE9siaZC7oD9RqHLQ=";

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
