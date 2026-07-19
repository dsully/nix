{
  config,
  lib,
  pkgs,
  ...
}: {
  options.programs.icm.enable =
    lib.mkEnableOption "ICM (Inter-Claude Memory) integration across Claude, Codex, and OpenCode"
    // {default = true;};

  config = lib.mkIf config.programs.icm.enable {
    home.packages = [pkgs.llm-agents.icm];

    programs.opencode.extraPlugins = ["${pkgs.llm-agents.icm}/plugins/opencode-icm.ts"];
  };
}
