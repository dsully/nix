{
  pkgs,
  inputs,
  ...
}: let
  craneLib = inputs.crane.mkLib pkgs;

  rev = "fffd3e5cfbf03b6b502bb4a34d49ef8f5e3bc802";
  version = "0.0.7-${rev}";

  src = pkgs.fetchFromGitHub {
    inherit rev;
    owner = "astral-sh";
    repo = "ruff";
    hash = "sha256-AC2AXMcLSDeZ+uavy1Ho9k34bWPhyJfvlq+kjS0KXOc=";
  };

  commonArgs = {
    inherit src version;
    pname = "ty";
    strictDeps = true;
    cargoExtraArgs = "--package=ty";
    nativeBuildInputs = with pkgs; [installShellFiles];
    env.TY_VERSION = version;
  };

  cargoArtifacts = craneLib.buildDepsOnly commonArgs;
in
  craneLib.buildPackage (commonArgs
    // {
      inherit cargoArtifacts;
      doCheck = false;

      postInstall = pkgs.lib.optionalString (pkgs.stdenv.hostPlatform.emulatorAvailable pkgs.buildPackages) (
        let
          emulator = pkgs.stdenv.hostPlatform.emulator pkgs.buildPackages;
        in ''
          installShellCompletion --cmd ty \
            --bash <(${emulator} $out/bin/ty generate-shell-completion bash) \
            --fish <(${emulator} $out/bin/ty generate-shell-completion fish) \
            --zsh <(${emulator} $out/bin/ty generate-shell-completion zsh)
        ''
      );

      passthru.updateScript = pkgs.nix-update-script {extraArgs = ["--version=unstable"];};

      meta = {
        description = "Extremely fast Python type checker and language server, written in Rust";
        homepage = "https://github.com/astral-sh/ruff";
        changelog = "https://github.com/astral-sh/ty/blob/${version}/CHANGELOG.md";
        license = pkgs.lib.licenses.mit;
        mainProgram = "ty";
      };
    })
