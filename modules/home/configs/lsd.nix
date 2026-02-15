{config, ...}: let
  c = config.colors;
in {
  programs.lsd = {
    enable = true;
    enableFishIntegration = false;

    settings = {
      classic = false;
      blocks = [
        "permission"
        "user"
        "group"
        "size"
        "date"
        "name"
      ];
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
      user = c.white.base;
      group = c.white.base;

      permission = {
        read = c.cyan.base;
        write = c.cyan.bright;
        exec = c.white.bright;
        exec-sticky = c.red.base;
        no-access = c.white.bright;
      };

      date = {
        hour-old = c.white.bright;
        day-old = c.white.base;
        older = c.white.dim;
      };

      size = {
        none = c.cyan.base;
        small = c.cyan.bright;
        medium = c.blue.base;
        large = c.blue.bright;
      };

      inode = {
        valid = c.cyan.bright;
        invalid = c.red.base;
      };

      links = {
        valid = c.cyan.bright;
        invalid = c.red.base;
      };

      tree-edge = c.red.base;
    };
  };
}
