{
  lib,
  writeShellApplication,
  alejandra,
  deadnix,
  statix,
  git,
  runCommand,
  flake ? ./.,
}: let
  formatter = writeShellApplication {
    name = "formatter";

    runtimeInputs = [
      alejandra
      deadnix
      statix
    ];

    text = ''
      set -euo pipefail

      if [[ $# = 0 ]]; then
        prj_root=$(git rev-parse --show-toplevel 2>/dev/null || echo .)
        set -- "$prj_root"
      fi

      set -x

      alejandra "$@"
      deadnix "$@"
      statix check "$@"
    '';

    meta.description = "Format and lint nix files";
  };

  check =
    runCommand "format-check"
    {
      nativeBuildInputs = [
        formatter
        git
      ];

      meta.platforms = lib.platforms.linux;
    }
    ''
      export HOME=$NIX_BUILD_TOP/home

      cp --no-preserve=mode --preserve=timestamps -r ${flake} source
      cd source
      git init --quiet
      git add .
      shopt -s globstar
      formatter **/*.nix
      if ! git diff --exit-code; then
        echo "-------------------------------"
        echo "aborting due to above changes ^"
        exit 1
      fi
      touch $out
    '';
in
  formatter
  // {
    passthru =
      formatter.passthru
      // {
        tests = {
          inherit check;
        };
      };
  }
