{
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
in {
  home.sessionVariables = {
    _ZO_DATA_DIR = "${config.xdg.dataHome}/zoxide";
    _ZO_FZF_OPTS = "${fzfOpts} --bind=ctrl-z:ignore --exit-0 --info=default --layout=reverse-list --no-sort --select-1";
  };

  programs = {
    fish.functions.prune-zoxide = {
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

    zoxide = {
      enable = true;
      enableFishIntegration = true;
      options = [
        "--cmd j"
      ];
    };
  };
}
