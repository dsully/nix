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
          hyperfine
          jq
          scc
          sq
          sqlite
          tree-sitter
          typos
          xan
          yq-go
        ]
        ++ (with my.pkgs; [
          debtmap
        ]);
    };

    programs.uv.tool.packages = [
      "big-code-analysis-cli"
    ];
  };
}
