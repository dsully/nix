{
  config,
  lib,
  pkgs,
  ...
}: let
  c = config.colors;
in {
  programs = {
    eza = {
      enable = true;
      enableFishIntegration = false;

      colors = "auto";
      git = true;
      icons = "auto";

      extraOptions = [
        "--ignore-glob=*.egg-info|.git|.mypy_cache|.pytest_cache|.ruff_cache|__breadboard__|__pycache__|__pypackages__|build-results"
        "--sort=name"
        "--time-style=long-iso"
      ];

      theme = {
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

        punctuation.foreground = c.red.base;
      };
    };

    fish.functions = {
      ls = {
        wraps = "eza";
        description = "Use eza with common ls flag cluster compatibility";
        body =
          # fish
          ''
            set -l args

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
                                set -a args --sort=modified
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

            ${lib.getExe pkgs.eza} $args
          '';
      };
    };
  };
}
