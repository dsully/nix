{pkgs, ...}: {
  home = {
    packages = with pkgs; [
      aichat
      better-commits # git bc
      curlconverter
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
    ];
  };
}
