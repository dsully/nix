{pkgs, ...}:
with pkgs;
  python3.pkgs.buildPythonApplication rec {
    pname = "bake";
    version = "1.3.0";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "EbodShojaei";
      repo = pname;
      rev = "f4b1c9f2424e3175b49771e05d2ea224c70f9db1";
      hash = "sha256-rfVMFMqkQRQpq5xIUcukyHm0+ETpcCcGrcgCDx+oiZE=";
    };

    nativeBuildInputs = [
      installShellFiles
    ];

    build-system = [
      python3.pkgs.hatchling
    ];

    dependencies = with python3.pkgs; [
      rich
      typer
    ];

    postInstall = lib.optionalString (stdenv.hostPlatform.emulatorAvailable buildPackages) (
      let
        emulator = stdenv.hostPlatform.emulator buildPackages;
      in ''
        installShellCompletion --cmd mbake \
          --bash <(${emulator} $out/bin/mbake completions bash) \
          --fish <(${emulator} $out/bin/mbake completions fish) \
          --zsh <(${emulator} $out/bin/mbake completions zsh)
      ''
    );

    meta = {
      description = "Mbake is a Python-based Makefile formatter and linter that enforces consistent formatting according to Makefile best practices.";
      homepage = "https://github.com/EbodShojaei/bake";
      changelog = "https://github.com/EbodShojaei/bake/blob/${src.rev}/CHANGELOG.md";
      license = lib.licenses.mit;
      mainProgram = "mbake";
    };
  }
