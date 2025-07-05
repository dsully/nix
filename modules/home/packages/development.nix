{
  flake,
  pkgs,
  ...
}: {
  home = {
    packages = with (pkgs // ((flake.inputs.upstream or flake).packages.${pkgs.system} or {}));
      [
        claude-code
        # Until 0.34+ hits nixpkgs
        (pkgs.codebook.overrideAttrs (oldAttrs: {
          doCheck = false;
          patches =
            (oldAttrs.patches or [])
            ++ [
              (pkgs.fetchpatch {
                url = "https://github.com/blopker/codebook/pull/86.patch";
                sha256 = "sha256-s4GrIbyYho+znGuXljNr+AIB6ulBKZKRHA8OS+3EBms=";
              })
            ];
        }))
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
      ];
  };
}
