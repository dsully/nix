{
  programs.lsd = {
    enable = true;
    enableFishIntegration = false;

    settings = {
      classic = false;
      blocks = ["permission" "user" "group" "size" "date" "name"];
      color = {
        when = "auto";
        theme = "custom";
      };
      date = "date";
      dereference = false;
      icons = {
        when = "auto";
        theme = "fancy";
        separator = " ";
      };
      ignore-globs = [
        "*.egg-info"
        ".git"
        ".mypy_cache"
        ".pytest_cache"
        ".ruff_cache"
        "__breadboard__"
        "__pycache__"
        "__pypackages__"
        "build-results"
      ];
      indicators = true;
      layout = "grid";
      recursion.enabled = false;
      size = "short";
      hyperlink = "never";
      permission = "rwx";
      sorting = {
        column = "name";
        reverse = false;
        dir-grouping = "none";
      };
      no-symlink = false;
      total-size = false;
      symlink-arrow = "⇒";
      header = false;
    };

    colors = {
      user = "#e5e9f0";
      group = "#e5e9f0";

      permission = {
        read = "#8fbcbb";
        write = "#88c0d0";
        exec = "#eceff4";
        exec-sticky = "#bf616a";
        no-access = "#eceff4";
      };

      date = {
        hour-old = "#eceff4";
        day-old = "#e5e9f0";
        older = "#d8dee9";
      };

      size = {
        none = "#8fbcbb";
        small = "#88c0d0";
        medium = "#81a1c1";
        large = "#5e81ac";
      };

      inode = {
        valid = "#88c0d0";
        invalid = "#bf616a";
      };

      links = {
        valid = "#88c0d0";
        invalid = "#bf616a";
      };

      tree-edge = "#bf616a";
    };
  };
}
