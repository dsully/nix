{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "ty";
    rev = "b5b4917d7f4a324f5d32cc55dfb1d08e75cc9e6f";
    version = "0.0.1a28-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "astral-sh";
      repo = "ruff";
      hash = "sha256-dEZqaKp3gXf/pSYr1BMqdeuYoMRhz05753Fmk0mIJ2g=";
    };

    cargoBuildFlags = ["--package=ty"];
    cargoHash = "sha256-ySR1pe9zwihjTzr3qhv71LuJbrhBWgZ+z+n9qEEern4=";
    doCheck = false;
    nativeBuildInputs = [installShellFiles];

    env.TY_VERSION = version;

    postInstall = lib.optionalString (stdenv.hostPlatform.emulatorAvailable buildPackages) (
      let
        emulator = stdenv.hostPlatform.emulator buildPackages;
      in ''
        installShellCompletion --cmd ${pname} \
          --bash <(${emulator} $out/bin/${pname} generate-shell-completion bash) \
          --fish <(${emulator} $out/bin/${pname} generate-shell-completion fish) \
          --zsh <(${emulator} $out/bin/${pname} generate-shell-completion zsh)
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
