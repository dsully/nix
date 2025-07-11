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
        (pkgs.opencode.overrideAttrs (
          oldAttrs: let
            newNodeModulesHash = {
              "aarch64-darwin" = "sha256-uk8HQfHCKTAW54rNHZ1Rr0piZzeJdx6i4o0+xKjfFZs=";
              "x86_64-linux" = "sha256-uk8HQfHCKTAW54rNHZ1Rr0piZzeJdx6i4o0+xKjfFZs=";
            };
          in {
            version = "0.2.27";
            src = pkgs.fetchFromGitHub {
              owner = "sst";
              repo = "opencode";
              rev = "b4950a157cb8393e02b925dddf37268fffba525e";
              sha256 = "sha256-QJRN4tU9yZlj3C3ZkVgXTSsKigVPt4thHhk5IXz+6jg=";
            };
            doCheck = false;

            tui = (oldAttrs.tui or (pkgs.buildGoModule {})).overrideAttrs (_: {
              vendorHash = "sha256-0vf4fOk32BLF9/904W8g+5m0vpe6i6tUFRXqDHVcMIQ=";
            });

            node_modules = (oldAttrs.node_modules or (pkgs.stdenvNoCC.mkDerivation {})).overrideAttrs (_: {
              outputHash = newNodeModulesHash.${pkgs.stdenv.hostPlatform.system};
            });
          }
        ))
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
