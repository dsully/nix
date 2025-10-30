{
  lib,
  my,
  pkgs,
  ...
}: {
  home = {
    file = {
      ".local/bin/pbcopy" = {
        force = true;
        source = pkgs.writeScript "pbcopy" ''
          ${lib.getExe pkgs.fish}

          # https://carlosbecker.com/posts/pbcopy-pbpaste-open-ssh/

          if set -q SSH_TTY
              if test -p /dev/stdin
                  cat - | nc -q1 localhost 2224
              else
                  nc -q1 localhost 2224
              end
          else
              echo "Nothing to do!"
          end
        '';
      };

      ".local/bin/pbpaste" = {
        force = true;
        source = pkgs.writeScript "pbpaste" ''
          ${lib.getExe pkgs.fish}

          if set -q SSH_TTY
              nc -q1 -d localhost 2225
          else
              echo "Nothing to do!"
          end
        '';
      };

      ".local/bin/xdg-open".source = lib.getExe my.pkgs.magic-opener;
    };
  };
}
