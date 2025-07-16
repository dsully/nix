{
  flake,
  pkgs,
  ...
}: {
  home = {
    packages = with (pkgs // ((flake.inputs.upstream or flake).packages.${pkgs.system} or {}));
      [
        codebook
        cyme
        dive
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
        yarn
        yek
        yq
        zig
      ]
      ++ [
        aichat
        better-commits # git bc
        curlconverter
        opencode-updated
      ];
  };
}
