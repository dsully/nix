{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "2b731d19b9b9bfa7f574a5a963bd6a2f14fc584a";
    pname = "ty";
    version = "0.0.1-alpha.10-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "astral-sh";
      repo = "ruff";
      hash = "sha256-WfAflON+fTS01kfeCwiPLLyqXJiFIJq/zZY00S8DCKA=";
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
