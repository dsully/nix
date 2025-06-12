{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "8123dab05aaf46bb893cf82854c34af1572cc130";
    pname = "ty";
    version = "0.0.1-alpha.8-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "astral-sh";
      repo = "ruff";
      hash = "sha256-iP90HZPUnkQ7w7TrptanZRxj1duTHSFDM/ZJgLtgjZA=";
    };

    cargoBuildFlags = ["--package=ty"];
    cargoHash = "sha256-eKshsWG+WGNFuypkXzRsCPK27Z5qOE1JZZHeShdOzcU=";

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
