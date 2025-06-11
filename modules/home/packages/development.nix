{
  flake,
  pkgs,
  ...
}: {
  home = {
    packages = with (pkgs // ((flake.inputs.upstream or flake).packages.${pkgs.system} or {}));
      [
        claude-code
        cyme
        fork-cleaner
        fx
        gh
        ghq
        gibo
        git
        git-dive
        git-ignore
        git-lfs
        git-quick-stats
        git-sizer
        git-who
        glow
        gnused
        go
        gofumpt
        gotools
        gron
        helix
        hyperfine
        jq
        kickstart
        nodejs
        ruff
        rye
        scc
        sq
        sqlite
        tree-sitter
        typos
        uv
        vivid
        xan
        yek
        yq
        zig
      ]
      ++ [
        aichat
        better-commits # git bc
        curlconverter
      ];
  };
}
