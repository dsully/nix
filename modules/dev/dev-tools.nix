{
  mkUserModule,
  config,
  lib,
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

      sessionVariables = {
        GHIDRA_INSTALL_DIR = "${pkgs.ghidra}/lib/ghidra";
        JAVA_HOME = toString pkgs.jdk25;
        REA_KUNA_COMMAND = lib.getExe pkgs.kuna;
      };

      packages = with pkgs;
        [
          ast-grep
          ghidra
          gibo
          gnused
          hyperfine
          jq
          kuna
          rea
          resvg
          scc
          sqlite
          typos
        ]
        ++ (with my.pkgs; [
          debtmap
          lini
        ]);
    };

    programs.uv.tool.packages = [
      "big-code-analysis-cli"
    ];
  };
}
