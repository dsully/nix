{config, ...}: let
  c = config.colors;
  inherit (config.colors) noHash;
in {
  programs.vivid = {
    enable = true;

    themes = {
      nord = {
        colors = {
          polar-night-nord0 = noHash c.black.dim;
          polar-night-nord1 = noHash c.black.base;
          polar-night-nord2 = noHash c.black.bright;
          polar-night-nord3 = noHash c.gray.base;

          snow-storm-nord4 = noHash c.white.dim;
          snow-storm-nord5 = noHash c.white.base;
          snow-storm-nord6 = noHash c.white.bright;

          frost-nord7 = noHash c.cyan.base;
          frost-nord8 = noHash c.cyan.bright;
          frost-nord9 = noHash c.blue.base;
          frost-nord10 = noHash c.blue.bright;

          aurora-nord11 = noHash c.red.base;
          aurora-nord12 = noHash c.orange.base;
          aurora-nord13 = noHash c.yellow.base;
          aurora-nord14 = noHash c.green.base;
          aurora-nord15 = noHash c.magenta.base;
        };

        core = {
          regular_file = {
            foreground = "frost-nord8";
            font-style = "underline";
          };

          directory = {
            foreground = "frost-nord10";
            font-style = "bold";
          };

          executable_file = {
            foreground = "frost-nord7";
            font-style = "bold";
          };

          symlink = {
            foreground = "frost-nord8";
          };

          broken_symlink = {
            foreground = "aurora-nord11";
            # background = "polar-night-nord0";
          };

          missing_symlink_target = {
            foreground = "snow-storm-nord6";
            background = "aurora-nord11";
            font-style = "bold";
          };

          fifo = {
            foreground = "frost-nord7";
            font-style = "underline";
          };

          socket = {
            foreground = "frost-nord8";
          };

          character_device = {
            foreground = "aurora-nord13";
          };

          block_device = {
            foreground = "aurora-nord13";
            font-style = "bold";
          };

          normal_text = {
            foreground = "snow-storm-nord6";
          };

          reset_to_normal = {};
          file_with_capability = {};
          multi_hard_link = {};
          door = {};
          setgid = {};
          setuid = {};
          other_writable = {};

          sticky = {
            foreground = "snow-storm-nord6";
            font-style = "bold";
          };

          sticky_other_writable = {
            foreground = "snow-storm-nord6";
            font-style = "bold";
          };
        };

        text = {
          foreground = "snow-storm-nord6";
          todo = {
            font-style = "bold";
          };
        };

        markup = {
          foreground = "snow-storm-nord6";
        };

        programming = {
          foreground = "snow-storm-nord6";
        };

        media = {
          foreground = "aurora-nord14";
        };

        office = {
          foreground = "aurora-nord14";
        };

        archives = {
          foreground = "aurora-nord14";
          font-style = "bold";
        };

        executable = {
          foreground = "frost-nord7";
          font-style = "bold";
          symlink = {
            foreground = "frost-nord8";
          };
        };

        unimportant = {
          foreground = "polar-night-nord3";
        };
      };
    };

    activeTheme = "nord";
  };
}
