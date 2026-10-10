{
  mkUserModule,
  config,
  lib,
  pkgs,
  ...
}: let
  fzfCfg = config.programs.fzf;

  renderedColors = colors: lib.concatStringsSep "," (lib.mapAttrsToList (name: value: "${name}:${value}") colors);

  fzfOpts =
    lib.concatStringsSep " " fzfCfg.defaultOptions
    + lib.optionalString (fzfCfg.colors != {}) " --color ${renderedColors fzfCfg.colors}";
in
  mkUserModule {
    name = "zoxide";

    home = {
      home.sessionVariables = {
        _ZO_DATA_DIR = "${config.xdg.dataHome}/zoxide";
        _ZO_FZF_OPTS = "${fzfOpts} --bind=ctrl-z:ignore --exit-0 --info=default --layout=reverse-list --no-sort --select-1";
      };

      programs = {
        fish = {
          functions.prune-zoxide = {
            description = "Remove paths that are no longer on disk in zoxide";
            body =
              # fish
              ''
                ${lib.getExe pkgs.zoxide} query --list --all | while read -l path
                    if not test -e "$path"
                        ${lib.getExe pkgs.zoxide} remove "$path"
                    end
                end
              '';
          };

          interactiveShellInit =
            lib.mkAfter
            # fish
            ''
              functions -q cd; and functions -c cd __zoxide_original_cd

              function cd --wraps=__zoxide_original_cd
                if test (count $argv) -gt 0; and test "$argv[1]" != -; and not test -d "$argv[1]"

                  set -l result (command zoxide query --exclude (__zoxide_pwd) -- $argv 2>/dev/null)

                  if test $status -eq 0
                    set -l current_root (git rev-parse --show-toplevel 2>/dev/null)

                    if test -n "$current_root"
                      set -l worktrees (git worktree list --porcelain 2>/dev/null | string match 'worktree *' | string replace 'worktree ' "")

                      for wt in $worktrees
                        test "$wt" = "$current_root"; and continue
                        set -l remapped (string replace "$wt/" "$current_root/" "$result")

                        if test "$remapped" != "$result" -a -d "$remapped"
                          __zoxide_cd $remapped
                          return
                        end
                      end
                    end

                    __zoxide_cd $result
                    return
                  end
                end

                __zoxide_original_cd $argv
              end
            '';
        };

        zoxide = {
          enable = true;
          enableFishIntegration = true;
          options = [
            "--cmd j"
          ];
        };
      };
    };
  }
