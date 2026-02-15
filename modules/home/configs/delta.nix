{config, ...}: let
  c = config.colors;
in {
  programs.delta = {
    enable = true;
    enableGitIntegration = true;

    options = {
      hyperlinks = true;
      keep-plus-minus-markers = false;
      line-numbers = false;
      navigate = true;
      relative-paths = true;
      side-by-side = false;
      true-color = "always";

      bg-green = c.green.dim;
      bg-red = c.red.dim;

      blame-code-style = "syntax";
      blame-format = "{author:<18} {commit:<6} {timestamp:<15}";
      blame-palette = "${c.black.dim} ${c.black.base} ${c.black.bright}";

      file-added-label = "[+]";
      file-copied-label = "[==]";
      file-modified-label = "[*]";
      file-removed-label = "[-]";
      file-renamed-label = "[->]";
      file-style = "omit";
      file-transformation = "s,(.*),  $1,";

      hunk-header-decoration-style = "blue ul";
      hunk-header-file-style = "blue bold";
      hunk-header-line-number-style = "white bold";
      hunk-header-style = "file line-number syntax bold italic";
      hunk-label = "";

      minus-emph-style = "white bg-red";
      minus-non-emph-style = "syntax normal";
      minus-style = "white bg-red";
      plus-emph-style = "black bg-green";
      plus-non-emph-style = "syntax normal";
      plus-style = "black bg-green";

      syntax-theme = "Nord";
      width = "variable";
      whitespace-error-style = "black bold";
      zero-style = "syntax";
    };
  };
}
