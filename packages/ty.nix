{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "ty";
    rev = "81c97e9e9437ae68e23c047e4c6fb2abcf0c80d6";
    version = "0.0.1a27-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "astral-sh";
      repo = "ruff";
      hash = "sha256-p71Gk6/kt5EuAshgnK1rEln7s15IXEZEuESNd2Rjz3E=";
    };

    cargoBuildFlags = ["--package=ty"];
    cargoHash = "sha256-KW8GYxSOVqInQ8hJNyu4RpU/c/mERl7zrnLLjnhYvYo=";
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
