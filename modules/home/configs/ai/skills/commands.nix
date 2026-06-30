{
  config,
  inputs,
  lib,
  ...
}: let
  asLib = inputs.agent-skills.lib.agent-skills;
  cfg = config.programs.agent-skills;

  # The set of skills selected through agent-skills (enable + enableAll) — the
  # single source of truth. allowlistFor mirrors the agent-skills module's own
  # selection so this never drifts from what actually gets installed.
  allowlist = asLib.allowlistFor {
    inherit (cfg) catalog;
    inherit (cfg) sources;
    enableAll = cfg.skills.enableAll;
    enable = cfg.skills.enable;
  };

  # First `field: ` value from a SKILL.md frontmatter, with a surrounding
  # double-quote pair stripped (some skills quote their description, and toJSON
  # re-quotes below).
  fieldValue = field: content: let
    parts = lib.splitString "${field}: " content;
    raw =
      if builtins.length parts >= 2
      then lib.head (lib.splitString "\n" (builtins.elemAt parts 1))
      else "";
  in
    if lib.hasPrefix "\"" raw && lib.hasSuffix "\"" raw && builtins.stringLength raw >= 2
    then lib.removeSuffix "\"" (lib.removePrefix "\"" raw)
    else raw;

  # SKILL.md body with its leading `--- … ---` frontmatter stripped.
  skillBody = content: let
    afterOpen = lib.removePrefix "---\n" content;
    segments = lib.splitString "\n---\n" afterOpen;
  in
    if lib.hasPrefix "---\n" content && builtins.length segments >= 2
    then lib.concatStringsSep "\n---\n" (builtins.tail segments)
    else content;

  # Render a selected skill into a tool command: minimal `description`
  # frontmatter (so the skill's `name:`/skill-only keys don't leak into the
  # command) plus the skill body as the prompt. claude and opencode share this
  # shape; diverge here if either ever needs tool-specific fields (claude
  # argument-hint/allowed-tools, opencode agent/subtask/model).
  renderCommand = content: ''
    ---
    description: ${builtins.toJSON (fieldValue "description" content)}
    ---

    ${lib.trim (skillBody content)}
  '';

  # Derive one slash command per selected skill for the tools with a native
  # commands option (claude-code, opencode). agent-skills stays the only place
  # skills are defined; codex/pi receive the skills themselves via agent-skills
  # targets but have no commands option.
  #
  # The id carries any source idPrefix, so a namespaced skill `foo/bugs`
  # becomes `/foo:bugs` in claude and `/foo/bugs` in opencode.
  skillCommands = lib.listToAttrs (map
    (id: lib.nameValuePair id (renderCommand (builtins.readFile "${cfg.catalog.${id}.absPath}/SKILL.md")))
    (builtins.filter (id: cfg.catalog ? ${id}) allowlist));
in {
  config = lib.mkIf cfg.enable {
    programs.claude-code.commands = skillCommands;
    programs.opencode.commands = skillCommands;
  };
}
