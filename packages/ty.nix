{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "28ab61d8850af9abe7f5b3f0406008b8abde4f8c";
    pname = "ty";
    version = "0.12.1";

    src = fetchFromGitHub {
      inherit rev;
      owner = "astral-sh";
      repo = "ruff";
      hash = "sha256-mpL2bFKGSxPsddXKLxXDeIDXaKEyhkvsINohyYHBFhM=";
    };

    cargoBuildFlags = ["--package=ty"];
    cargoHash = "sha256-s1KSEByAcsNz2fGN5hh/wXUACKdDVD7hS8aA8wC9mYs=";

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
