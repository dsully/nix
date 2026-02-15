{
  pname,
  pkgs,
  flake,
}: let
  formatter = pkgs.writeShellApplication {
    name = pname;

    runtimeInputs = [
      pkgs.alejandra
      pkgs.deadnix
      pkgs.statix
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
    pkgs.runCommand "format-check"
    {
      nativeBuildInputs = [
        formatter
        pkgs.git
      ];

      meta.platforms = pkgs.lib.platforms.linux;
    }
    ''
      export HOME=$NIX_BUILD_TOP/home

      cp --no-preserve=mode --preserve=timestamps -r ${flake} source
      cd source
      git init --quiet
      git add .
      shopt -s globstar
      ${pname} **/*.nix
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
