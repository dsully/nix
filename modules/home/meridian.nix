{
  config,
  perSystem,
  ...
}: {
  home.file."${config.xdg.binHome}/opencode" = {
    force = true;
    source = "${perSystem.self.meridian}/libexec/meridian/opencode-wrapper";
  };

  programs.opencode.settings.plugin = [
    "${perSystem.self.meridian}/libexec/meridian/plugin/meridian.ts"
    # "opencode-claude-auth"
    "opencode-gemini-auth"
    # "opencode-with-claude"
  ];
}
