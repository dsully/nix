{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "a2de81cb27541b7f09d57644539cea566cc0ece1";
    pname = "ty";
    version = "0.0.1-alpha.8-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "astral-sh";
      repo = "ruff";
      hash = "sha256-ZU36WWSmInvr6v6KjXHZ7G58emo194p0iW6kKvderJo=";
    };

    cargoBuildFlags = ["--package=ty"];
    cargoHash = "sha256-5XEdHsTGRhc6qb6HFWiwPC7scr9KMrmJY2tqlqxMPQA=";

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
      version = version;
      mainProgram = pname;
    };
  }
