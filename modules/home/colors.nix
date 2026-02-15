{lib, ...}: {
  options.colors = lib.mkOption {
    type = lib.types.attrs;
    readOnly = true;
    description = "Nord color palette - source of truth for all color references.";
  };

  config.colors = let
    # Strip # prefix for tools that want bare hex (vivid, fish themes, etc.)
    noHash = s: lib.removePrefix "#" s;
  in {
    inherit noHash;

    # Nord palette: https://www.nordtheme.com/docs/colors-and-palettes
    # Names match ~/.config/nvim/lua/config/highlights.lua
    red = {
      base = "#bf616a";
      bright = "#d06f79";
      dim = "#a54e56";
    };
    orange = {
      base = "#d08770";
      bright = "#d89079";
      dim = "#b46950";
    };
    green = {
      base = "#a3be8c";
      bright = "#b1d196";
      dim = "#8aa872";
    };
    yellow = {
      base = "#ebcb8b";
      bright = "#f0d399";
      dim = "#d9b263";
    };
    magenta = {
      base = "#b48ead";
      bright = "#c895bf";
      dim = "#9d7495";
    };
    blue = {
      base = "#81a1c1";
      bright = "#5e81ac";
      dim = "#668aab";
    };
    black = {
      base = "#3b4252";
      bright = "#434c5e";
      dim = "#2e3440";
      dark = "#222730";
    };
    cyan = {
      base = "#8fbcbb";
      bright = "#88c0d0";
      dim = "#69a7ba";
    };
    white = {
      base = "#e5e9f0";
      bright = "#eceff4";
      dim = "#d8dee9";
    };
    gray = {
      base = "#4c566a";
      bright = "#667084";
      dim = "#2b303b";
    };

    fg = "#e5e9f0";
    bg = "#2e3440";

    blend = {
      red = "#3c3944";
      yellow = "#414348";
      green = "#3a4248";
      turquoise = "#37424e";
      blue = "#384356";
      comment = "#5c6881";
    };

    extra = {
      fzfHl = "#616e88";
      cppIcon = "#95d3af";
    };
  };
}
