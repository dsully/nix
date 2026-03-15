{
  my,
  pkgs,
  ...
}: {
  home = {
    packages = with pkgs; [
      ast-grep
      codebook
      cyme
      dive
      fork-cleaner
      fx
      gibo
      git-dive
      git-ignore
      git-quick-stats
      git-sizer
      git-trim
      git-who
      glow
      gnused
      go
      gron
      hyperfine
      jq
      kickstart
      nodejs
      scc
      sq
      sqlite
      tree-sitter
      typos
      uv
      xan
      yarn
      yek
      yq

      my.pkgs.worktrunk
    ];
  };
}
