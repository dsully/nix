{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "05b1b788a047dbcfcf6d368a5026ce8dd23d187a";
    pname = "ty";
    version = "0.0.1a13-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "astral-sh";
      repo = "ruff";
      hash = "sha256-IU8Q0U1CoBe1s2n1KPAROE+ZlcEoGzL/bI/ntkO8Zdg=";
    };

    cargoBuildFlags = ["--package=ty"];
    cargoHash = "sha256-OUHesxLkq45YmMBjUMb6Ny31/6zSDmfklzxSOZzhLfw=";

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
