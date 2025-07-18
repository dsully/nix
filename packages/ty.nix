{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "ba7ed3a6f99aa37c82b888c0ecea3ebf1ba0ec03";
    pname = "ty";
    version = "0.0.1a14-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "astral-sh";
      repo = "ruff";
      hash = "sha256-bSKPtZvv8yrlq4vZTf3kVJQ4Br2oW0zNe1C75qPZHSI=";
    };

    cargoBuildFlags = ["--package=ty"];
    cargoHash = "sha256-vhsXYqU3Y5xGDLE/AVkVIY4eweHbyR/E3RvGoHG+1ZE=";

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
