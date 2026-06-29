{
  config,
  lib,
  perSystem,
  ...
}: {
  options.programs.icm.enable =
    lib.mkEnableOption "ICM (Inter-Claude Memory) integration across Claude, Codex, and OpenCode"
    // {default = true;};

  config = lib.mkIf config.programs.icm.enable {
    home.packages = [perSystem.llm-agents.icm];

    programs.opencode.extraPlugins = ["${perSystem.llm-agents.icm}/plugins/opencode-icm.ts"];
  };
}
