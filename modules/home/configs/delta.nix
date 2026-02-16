{config, ...}: let
  c = config.colors;
in {
  programs.delta = {
    enable = true;
    enableGitIntegration = true;

    options = {
      hyperlinks = true;
      keep-plus-minus-markers = true;
      line-numbers = false;
      navigate = true;
      relative-paths = true;
      side-by-side = false;
      true-color = "always";

      blame-code-style = "syntax";
      blame-format = "{author:<18} {commit:<6} {timestamp:<15}";
      blame-palette = "${c.black.dim} ${c.black.base} ${c.black.bright}";

      file-added-label = "[+]";
      file-copied-label = "[==]";
      file-modified-label = "[*]";
      file-removed-label = "[-]";
      file-renamed-label = "[->]";
      file-style = "omit";
      file-transformation = "s,(.*),  $1,";

      hunk-header-decoration-style = "blue ul";
      hunk-header-file-style = "blue bold";
      hunk-header-line-number-style = "white bold";
      hunk-header-style = "file line-number syntax bold italic";
      hunk-label = "none";

      minus-emph-style = "syntax red";
      minus-non-emph-style = "syntax normal";
      minus-style = "red";
      plus-emph-style = "black green";
      plus-non-emph-style = "syntax normal";
      plus-style = "green";

      syntax-theme = "Nord";
      width = "variable";
      whitespace-error-style = "black bold";
      zero-style = "syntax";
    };
  };
}
