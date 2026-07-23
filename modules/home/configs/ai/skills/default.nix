{
  config,
  inputs,
  lib,
  ...
}: let
  cfg = config.programs.ai.skills;
  enabled = lib.filterAttrs (_: g: g.enable) cfg;

  # agent-skills source name: explicit `name` overrides the group's attr key.
  srcName = key: g:
    if g.name != null
    then g.name
    else key;

  sourceOf = g:
    (
      if g.input != null
      then {inherit (g) input;}
      else {inherit (g) path;}
    )
    // lib.optionalAttrs (g.subdir != null) {inherit (g) subdir;}
    // lib.optionalAttrs (g.idPrefix != null) {inherit (g) idPrefix;};

  groupType = lib.types.submodule {
    options = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether this skill group is active.";
      };
      name = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Name for the skill group.";
      };
      input = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Flake input name backing the group's agent-skills source.";
      };
      path = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Path backing the group's source (mutually exclusive with input).";
      };
      subdir = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Subdirectory under the source root holding the skills.";
      };
      idPrefix = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Namespace prepended to this group's discovered skill IDs.";
      };
      all = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable every skill discovered in this group's source.";
      };
      ids = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Specific skill IDs to enable from this group.";
      };
    };
  };
in {
  imports = [
    inputs.agent-skills.homeManagerModules.default
    ./commands.nix
  ];

  # Toggleable skill groups. Each group owns one agent-skills source plus its
  # selection, so enabling/disabling a group (e.g. `programs.ai.skills.python`)
  # registers/removes the source and its skills together — agent-skills stays
  # the single source of truth, fanning out to every tool + the derived slash
  # commands (see commands.nix).
  options.programs.ai.skills = lib.mkOption {
    type = lib.types.attrsOf groupType;
    default = {};
    description = "Named, individually toggleable skill groups.";
  };

  config = lib.mkMerge [
    {
      programs.agent-skills = {
        enable = true;
        targets = {
          agents.enable = false;
          claude.enable = true;
          codex.enable = true;
          opencode.enable = true;
          pi = {
            enable = true;
            dest = "${config.home.homeDirectory}/.pi/agent/skills";
            structure = "symlink-tree";
          };
          # zaly discovers skills from $XDG_CONFIG_HOME/zaly/skills/**/SKILL.md,
          # globbing with `follow: false` — it won't descend into symlinked skill
          # dirs, so copy-tree (real files via `rsync -aL`) is required, not
          # symlink-tree.
          zaly = {
            enable = true;
            dest = "${config.xdg.configHome}/zaly/skills";
            structure = "copy-tree";
          };
        };
      };

      programs.ai.skills = {
        process = {
          name = "superpowers";
          input = "superpowers";
          subdir = "skills";
          all = true;
        };
        essentials = {
          name = "essentials";
          input = "wshobson-agents";
          subdir = "plugins/developer-essentials/skills";
          ids = [
            "debugging-strategies"
            "e2e-testing-patterns"
            "error-handling-patterns"
          ];
        };
        python = {
          name = "python";
          input = "wshobson-agents";
          subdir = "plugins/python-development/skills";
          ids = [
            "python-anti-patterns"
            "python-code-style"
            "python-configuration"
            "python-design-patterns"
            "python-error-handling"
            "python-observability"
            "python-performance-optimization"
            "python-project-structure"
            "python-resilience"
            "python-resource-management"
            "python-testing-patterns"
            "python-type-safety"
            "uv-package-manager"
          ];
        };
        systems = {
          name = "systems";
          input = "wshobson-agents";
          subdir = "plugins/systems-programming/skills";
          ids = [
            "memory-safety-patterns"
          ];
        };
        local = {
          path = ./content;
          all = true;
        };
      };
    }

    (lib.mkIf (enabled != {}) {
      assertions =
        lib.mapAttrsToList (name: g: {
          assertion = (g.input != null) != (g.path != null);
          message = "programs.ai.skills.${name}: set exactly one of `input` or `path`.";
        })
        enabled;

      programs.agent-skills = {
        sources = lib.mapAttrs' (key: g: lib.nameValuePair (srcName key g) (sourceOf g)) enabled;
        skills = {
          enable = lib.concatMap (g: g.ids) (lib.attrValues enabled);
          enableAll = lib.mapAttrsToList srcName (lib.filterAttrs (_: g: g.all) enabled);
        };
      };
    })
  ];
}
