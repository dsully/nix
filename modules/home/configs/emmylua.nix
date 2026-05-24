{
  config,
  pkgs,
  ...
}: let
  jsonFormat = pkgs.formats.json {};
  emmyrc = extraLibraries:
    jsonFormat.generate "emmyrc.json" {
      "$schema" = "https://raw.githubusercontent.com/EmmyLuaLs/emmylua-analyzer-rust/refs/heads/main/crates/emmylua_code_analysis/resources/schema.json";
      diagnostics = {
        disable = [
          "missing-fields"
          "type-not-found"
          "undefined-field"
          "unnecessary-if"
        ];
        globals = [
          "Snacks"
          "bit"
          "colors"
          "defaults"
          "ev"
          "hl"
          "keys"
          "ns"
          "nvim"
          "package"
          "require"
          "vim"
        ];
        unusedLocalExclude = [
          "_*"
        ];
      };
      runtime = {
        version = "LuaJIT";
      };
      workspace = {
        ignoreDir = [
          "debug"
          "templates"
        ];
        ignoreGlobs = [
          "**/*_spec.lua"
        ];
        library =
          [
            "$VIMRUNTIME"
          ]
          ++ extraLibraries;
      };
    };
in {
  # home.file.".emmyrc.json".source = emmyrc [];

  home.file."${config.xdg.configHome}/nvim/.emmyrc.json".source = emmyrc [
    # "${config.xdg.dataHome}/nvim/lazy"
    "${config.xdg.dataHome}/nvim/site/pack/core/opt"
  ];
}
