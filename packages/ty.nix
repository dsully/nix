{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "27eee5a1a845498aa6a938281cea60c1b1f3f7c9";
    pname = "ty";
    version = "0.0.1a11-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "astral-sh";
      repo = "ruff";
      hash = "sha256-kbtg5fbpCO6Ne6oQqbz1enKG/AQv0381CchkCTC+0gw=";
    };

    cargoBuildFlags = ["--package=ty"];
    cargoHash = "sha256-m2eh6ep3+vc69NjRyGCngbuVx29vpZCGG4apc0dkGYs=";

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
