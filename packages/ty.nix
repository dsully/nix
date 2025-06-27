{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "18efe2ab46be03f2f3c4c71ba0946c21f35f4c8e";
    pname = "ty";
    version = "0.12.1";

    src = fetchFromGitHub {
      inherit rev;
      owner = "astral-sh";
      repo = "ruff";
      hash = "sha256-xNi9abUW18O0I6m+gzdymkg8Ofe3V2qaW75/+X6qne4=";
    };

    cargoBuildFlags = ["--package=ty"];
    cargoHash = "sha256-5aGuC3S09lbsG+GBEBSt9KaVfWbycBCeeXsnV4fNU9w=";

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
