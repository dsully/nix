{
  config,
  lib,
  ...
}: let
  fzfCfg = config.programs.fzf;
  renderedColors = colors: lib.concatStringsSep "," (lib.mapAttrsToList (name: value: "${name}:${value}") colors);
  fzfOpts =
    lib.concatStringsSep " " fzfCfg.defaultOptions
    + lib.optionalString (fzfCfg.colors != {}) " --color ${renderedColors fzfCfg.colors}";
in {
  home.sessionVariables = {
    _ZO_FZF_OPTS = "${fzfOpts} --bind=ctrl-z:ignore --exit-0 --info=default --layout=reverse-list --no-sort --select-1";
  };

  programs.zoxide = {
    enable = true;
    options = [
      "--cmd j"
    ];
  };
}
