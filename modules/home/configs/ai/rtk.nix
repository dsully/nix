{
  config,
  lib,
  pkgs,
  ...
}: {
  options.programs.rtk.enable =
    lib.mkEnableOption "RTK (Rust Token Killer) shell-output compression for AI agents"
    // {
      default = false;
    };

  # The agent-specific wiring (Claude/Codex hooks + awareness, OpenCode plugin,
  # pi optimizer, shell-wrapper permission) lives in each agent's module and is
  # gated on programs.rtk.enable. This module owns the binary and its env.
  config = lib.mkIf config.programs.rtk.enable {
    home = {
      packages = [pkgs.llm-agents.rtk];
      sessionVariables.RTK_TELEMETRY_DISABLED = "1";
    };
  };
}
