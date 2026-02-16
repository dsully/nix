{
  inputs,
  pkgs,
  ...
}: let
  jsonFormat = pkgs.formats.json {};
  inherit (inputs.neovim-nightly-overlay.packages.${pkgs.stdenv.hostPlatform.system}) neovim;
in {
  home.file.".emmyrc.json".source = jsonFormat.generate "emmyrc.json" {
    "$schema" = "https://raw.githubusercontent.com/EmmyLuaLs/emmylua-analyzer-rust/refs/heads/main/crates/emmylua_code_analysis/resources/schema.json";
    diagnostics = {
      disable = [
        "missing-fields"
        "type-not-found"
        "undefined-field"
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
      ignoreGlobs = [
        "**/*_spec.lua"
      ];
      library = [
        "${neovim}/share/nvim/runtime"
        # "${config.xdg.dataHome}/nvim/lazy/"
      ];
      workspaceRoots = [
        "lua"
      ];
    };
  };
}
