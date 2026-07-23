{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;

  cfg = config.programs.zaly;

  jsonFormat = pkgs.formats.json {};
  zalyLib = import ./lib.nix {inherit lib;};

  # zaly loads its user config from $XDG_CONFIG_HOME/zaly/config.json
  # (@zaly/shared envPaths, XDG spec on darwin/linux).
  configPath = "${config.xdg.configHome}/zaly/config.json";

  # Collapse the typed options into the config tree, dropping unset (null)
  # fields so only explicitly-set keys are written.
  typedTree = {
    inherit (cfg) model reasoning tools plugins;
    ui = {inherit (cfg.ui) mode theme images reasoning copyOnSelect collapsedTools listHeight treeHeight sessionTree;};
    permissions = {inherit (cfg.permissions) preset allow deny ask;};
    skills = {inherit (cfg.skills) enabled actions actionPrefix;};
    commands = {inherit (cfg.commands) actionPrefix bash expr;};
    compaction = {inherit (cfg.compaction) enabled keepTokens reasoning summaryTokens threshold;};
    masking = {inherit (cfg.masking) enabled keepTurns minTokens delta target;};
    system = {inherit (cfg.system) bash git npm;};
  };

  # Freeform `settings` is the base; typed options win on overlap.
  finalSettings = lib.recursiveUpdate cfg.settings (zalyLib.filterNull typedTree);

  configFile = jsonFormat.generate "zaly-config.json" finalSettings;
in {
  imports = [./options.nix];

  config = mkIf cfg.enable {
    home = {
      packages = mkIf (cfg.package != null) [cfg.package];

      # zaly rewrites config.json in place via its `/config` command, so a
      # read-only /nix/store symlink would break it. Install a writable copy
      # instead: each activation restores declared state while runtime edits
      # persist in between. `install -d` first because macOS BSD `install`
      # ignores `-D`, and nothing else creates the config dir.
      activation.zalyConfig = mkIf (finalSettings != {}) (
        lib.hm.dag.entryAfter ["writeBoundary"] ''
          $DRY_RUN_CMD install -d ${builtins.dirOf configPath}
          $DRY_RUN_CMD install -m600 ${configFile} ${configPath}
        ''
      );
    };
  };
}
