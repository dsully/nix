{
  config,
  lib,
  pkgs,
  ...
}: let
  c = config.colors;
in {
  programs = {
    fish.interactiveShellInit =
      # fish
      ''
        set -gx EZA_CONFIG_DIR "${config.xdg.configHome}/eza"
      '';

    eza = {
      enable = true;
      enableFishIntegration = false;

      theme = {
        colourful = true;

        # extensions = {
        #   rs = {
        #     icon = {
        #       glyph = "🦀";
        #     };
        #   };
        # };

        file_type = {
          build = {
            foreground = c.white.dim;
            is_bold = false;
            underline = false;
          };
          compiled = {
            foreground = c.orange.base;
            is_bold = false;
            underline = false;
          };
          compressed = {
            foreground = c.red.base;
            is_bold = false;
            underline = false;
          };
          crypto = {
            foreground = c.green.base;
            is_bold = false;
            underline = false;
          };
          document = {
            foreground = c.blue.bright;
            is_bold = false;
            underline = false;
          };
          image = {
            foreground = c.magenta.base;
            is_bold = false;
            underline = false;
          };
          lossless = {
            foreground = c.cyan.bright;
            is_bold = false;
            underline = false;
          };
          music = {
            foreground = c.cyan.bright;
            is_bold = false;
            underline = false;
          };
          source = {
            foreground = c.white.dim;
            is_bold = false;
            underline = false;
          };
          temp = {
            foreground = c.gray.base;
            is_italic = false;
            underline = false;
          };
          video = {
            foreground = c.magenta.base;
            is_bold = false;
            underline = false;
          };
        };

        filekinds = {
          block_device = {
            foreground = c.magenta.base;
          };
          char_device = {
            foreground = c.magenta.base;
          };
          directory = {
            foreground = c.blue.base;
            is_bold = false;
          };
          executable = {
            foreground = c.green.bright;
            is_bold = false;
          };
          mount_point = {
            foreground = c.cyan.bright;
            is_bold = false;
          };
          normal = {
            foreground = c.white.dim;
            is_bold = false;
          };
          pipe = {
            foreground = c.gray.base;
          };
          socket = {
            foreground = c.gray.base;
          };
          special = {
            foreground = c.magenta.base;
          };
          symlink = {
            foreground = c.cyan.bright;
            is_bold = false;
          };
        };

        filenames = {
          "Cargo.lock" = {
            icon = {
              glyph = "🦀";
              foreground = c.white.dim;
            };
          };
          "Cargo.toml" = {
            icon = {
              glyph = "🦀";
              foreground = c.white.dim;
            };
          };
          "Dockerfile" = {
            icon = {
              glyph = "🐳";
              style = {
                foreground = c.white.dim;
              };
            };
          };
        };

        users = {
          group_other.foreground = c.white.base;
          group_root.foreground = c.white.base;
          group_yours.foreground = c.white.base;

          user_other.foreground = c.white.base;
          user_root.foreground = c.white.base;
          user_you.foreground = c.white.base;
        };

        perms = {
          group_execute.foreground = c.white.bright;
          group_read.foreground = c.cyan.base;
          group_write.foreground = c.cyan.bright;

          other_execute.foreground = c.white.bright;
          other_read.foreground = c.cyan.base;
          other_write.foreground = c.cyan.bright;

          special_other.foreground = c.red.base;
          special_user_file.foreground = c.red.base;

          user_execute_file.foreground = c.white.bright;
          user_execute_other.foreground = c.white.bright;
          user_read.foreground = c.cyan.base;
          user_write.foreground = c.cyan.bright;
        };

        date = {
          foreground = c.white.base;
        };

        size = {
          number_byte.foreground = c.cyan.base;
          unit_byte.foreground = c.cyan.base;
          number_kilo.foreground = c.cyan.bright;
          unit_kilo.foreground = c.cyan.bright;
          number_mega.foreground = c.blue.base;
          unit_mega.foreground = c.blue.base;
          number_giga.foreground = c.blue.bright;
          unit_giga.foreground = c.blue.bright;
          number_huge.foreground = c.blue.bright;
          unit_huge.foreground = c.blue.bright;
        };

        inode.foreground = c.cyan.bright;

        links = {
          normal.foreground = c.cyan.bright;
          multi_link_file.foreground = c.cyan.bright;
        };

        punctuation.foreground = c.white.base;
      };
    };

    fish.functions = {
      ls = {
        wraps = "eza";
        description = "Use eza with common ls flag cluster compatibility";
        body =
          # fish
          ''
            set -l args "--ignore-glob=*.egg-info|.git|.mypy_cache|.pytest_cache|.ruff_cache|__breadboard__|__pycache__|__pypackages__|build-results" \
              "--icons=always" \
              "--git" \
              "--sort=name" \
              "--time-style=long-iso"

            for arg in $argv
                if string match -qr '^-[A-Za-z0-9]+$' -- $arg
                    set -l chars (string split "" -- (string sub --start 2 -- $arg))

                    for char in $chars
                        switch $char
                            case l
                                set -a args --long
                            case a
                                set -a args --all
                            case A
                                set -a args --almost-all
                            case r
                                set -a args --reverse
                            case t
                                set -a args --sort=time
                            case S
                                set -a args --sort=size
                            case 1
                                set -a args --oneline
                            case F
                                set -a args --classify=auto
                            case '*'
                                set -a args -$char
                        end
                    end
                else
                    set -a args $arg
                end
            end

            LS_COLORS="" ${lib.getExe pkgs.eza} $args
          '';
      };
    };
  };
}
