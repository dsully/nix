{pkgs, ...}:
with pkgs;
  python3.pkgs.buildPythonApplication rec {
    pname = "bake";
    version = "1.3.1";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "EbodShojaei";
      repo = pname;
      rev = "0c0effaeff172aa00a79e25d6ad49c675ff29be1";
      hash = "sha256-y5vPYlAhHXTqctC5xmTtBxpmgtdeIixA6DwyvdpTvgI=";
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
