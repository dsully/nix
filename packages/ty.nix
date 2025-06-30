{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "e7aadfc28b5a1447c45d39017a37f1acd1001f14";
    pname = "ty";
    version = "0.12.1";

    src = fetchFromGitHub {
      inherit rev;
      owner = "astral-sh";
      repo = "ruff";
      hash = "sha256-kfWpMsPKEwVlHckq12xWZ0OVYV1T9fJOFSs41SRT5IE=";
    };

    cargoBuildFlags = ["--package=ty"];
    cargoHash = "sha256-1ANlQV4FsiV2MjfT/D1bUTzbd74nuUTRZyZ0FRyiS8s=";

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
