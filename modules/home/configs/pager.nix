# https://github.com/sharkdp/bat
{
  config,
  lib,
  pkgs,
  ...
}: let
  pager = lib.getExe pkgs.moor;
in {
  xdg.enable = true;

  home.sessionVariables = {
    BAT_PAGER = "${pager} -no-linenumbers -quit-if-one-screen";
    BAT_THEME = "Nord";
    MANPAGER = pager;
    MOOR = "-statusbar bold -no-linenumbers -no-clear-on-exit -style nord -colors 16M -wrap -quit-if-one-screen";
    PAGER = pager;
  };

  programs.bat = {
    enable = true;
    config = {
      style = "plain";
      theme = "Nord";
      italic-text = "always";
      map-syntax = [
        ".dockerignore:Git Ignore"
        ".eslintignore:Git Ignore"
        ".eslintrc:JSON"
        ".lua-format:YAML"
        ".luacheckrc:Lua"
        "${config.xdg.configHome}/ghostty/config*:Ghostty Config"
      ];
    };

    syntaxes = {
      Just.src = ./bat/syntaxes/Just.sublime-syntax;
      ghostty.src = ./bat/syntaxes/ghostty.sublime-syntax;
    };
  };
}
