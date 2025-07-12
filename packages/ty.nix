{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "4bc27133a9c1cecdfd53669662db1292b6c1dc83";
    pname = "ty";
    version = "0.0.1a14-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "astral-sh";
      repo = "ruff";
      hash = "sha256-/QNKQ6Pwst/vo/iNmnHdh7bE7BiimAPw/R+q0nhQOaE=";
    };

    cargoBuildFlags = ["--package=ty"];
    cargoHash = "sha256-hN1pKZs4DGWHX//E/3ra8iUI/jxsrYEGYGJJRriS0fY=";

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
