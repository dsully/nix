{
  editorconfig = {
    enable = true;

    settings = {
      "*" = {
        charset = "utf-8";
        end_of_line = "lf";
        trim_trailing_whitespace = true;
        insert_final_newline = true;
        indent_style = "space";
      };
      "*.{js,json,jsonc,ts,nix,yml,yaml}" = {
        indent_size = 2;
        max_line_length = 160;
      };
      "*.{py,rs}" = {
        indent_size = 4;
        max_line_length = 160;
      };
      "*.go" = {
        indent_size = 8;
        indent_style = "tab";
      };
      "Makefile" = {
        indent_style = "tab";
      };
      "just" = {
        indent_size = 4;
        indent_style = "tab";
      };
    };
  };
}
