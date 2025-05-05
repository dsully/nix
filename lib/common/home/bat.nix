# https://github.com/sharkdp/bat
{config, ...}: {
  xdg.enable = true;

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
  };
}
