{
  config,
  lib,
  pkgs,
  ...
}: {
  options.programs.zmx.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Whether to enable zmx terminal session persistence.";
  };

  # The fish glue (completions, picker, prompt indicator, conf.d auto-attach)
  # lives in dotfiles/fish and self-gates on `command -q zmx`, so removing the
  # package here is enough to make all of it inert.
  config = lib.mkIf config.programs.zmx.enable {
    home.packages = [pkgs.zmx];
  };
}
