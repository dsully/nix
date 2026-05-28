{
  config,
  lib,
  my,
  ...
}: {
  options.programs.icm.enable =
    lib.mkEnableOption "ICM (Inter-Claude Memory) integration across Claude, Codex, and OpenCode"
    // {default = true;};

  config = lib.mkIf config.programs.icm.enable {
    home.packages = [my.pkgs.icm];

    programs.opencode.extraPlugins = ["${my.pkgs.icm}/plugins/opencode-icm.ts"];
  };
}
