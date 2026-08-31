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
        # `ignoreDir` only excludes one specific directory relative to a
        # workspace root; it cannot match a directory name recursively
        # anywhere in the tree. Plugin test/spec dirs (which mock globals
        # like `assert`, `vim.deepcopy`, `vim.notify`) have to be excluded
        # via recursive globs instead.
        ignoreGlobs = [
          "**/*_spec.lua"
          "**/*.spec.lua"
          "**/*_test.lua"
          "**/test/**"
          "**/tests/**"
          "**/spec/**"
          "**/plenary/busted.lua"
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
    "${config.xdg.dataHome}/nvim/site/pack/core/opt"
  ];
}
