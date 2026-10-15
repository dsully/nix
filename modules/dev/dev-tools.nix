{
  mkUserModule,
  config,
  my,
  pkgs,
  ...
}:
mkUserModule {
  name = "dev-tools";

  home = {
    home = {
      file = {
        # Live-symlinked so Neovim's `zg` can add words without a rebuild.
        ".typos.toml".source = config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.dir}/typos/typos.toml";
      };

      packages = with pkgs;
        [
          ast-grep
          codebook
          cyme
          difftastic
          dive
          gibo
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
          xan
          yarn
          yq-go
        ]
        ++ (with my.pkgs; [
          debtmap
        ]);

      sessionVariables = {
        GOPATH = "${config.xdg.dataHome}/go";
      };
    };

    programs = {
      go = {
        enable = true;
        env.GOPATH = "${config.xdg.dataHome}/go";
      };

      uv.tool.packages = [
        "big-code-analysis-cli"
      ];
    };
  };
}
