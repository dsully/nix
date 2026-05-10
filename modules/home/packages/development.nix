{
  config,
  pkgs,
  ...
}: {
  home = {
    packages = with pkgs; [
      ast-grep
      codebook
      cyme
      dive
      gibo
      glow
      gnused
      go
      hyperfine
      jq
      nodejs
      scc
      sq
      sqlite
      tree-sitter
      typos
      uv
      xan
      yarn
      yq
    ];
  };

  programs.go = {
    enable = true;
    env.GOPATH = "${config.xdg.dataHome}/go";
  };
}
