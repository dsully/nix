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
      };

      programs.ai.skills = {
        # Superpowers skills are intentionally NOT registered here. The
        # superpowers plugin (see opencode.nix) already registers them itself via
        # config.skills.paths, so adding them through agent-skills too would write
        # them into opencode's discovery dir a second time and trigger a
        # "duplicate skill name" warning for every one at startup. Let the plugin
        # be the single owner. Trade-off: the plugin exposes superpowers' full
        # skill set (including brainstorming / receiving-code-review /
        # using-superpowers), not the curated subset this group used to select.
        improve = {
          name = "improve";
          input = "improve";
          subdir = "skills";
          all = true;
        };
        essentials = {
          name = "essentials";
          input = "wshobson-agents";
          subdir = "plugins/developer-essentials/skills";
          ids = [
            "error-handling-patterns"
          ];
        };
        # Every enabled skill's description sits in the system prompt for the
        # whole session, so a group is only worth carrying globally if it fires
        # on most repos. Language/framework groups are opt-in: turn them on in
        # the host or user config when working in that stack.
        python = {
          enable = lib.mkDefault false;
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
        authoring = {
          enable = lib.mkDefault false;
          name = "authoring";
          input = "softaworks";
          subdir = "skills";
          ids = [
            "agent-md-refactor"
            "command-creator"
            "plugin-forge"
            "skill-judge"
          ];
        };
        softaworks = {
          name = "systems";
          input = "softaworks";
          subdir = "skills";
          ids = [
            "commit-work"
            "crafting-effective-readmes"
            "naming-analyzer"
            "reducing-entropy"
          ];
          # Dropped from the global set (web/frontend and interpersonal writing —
          # rarely relevant here, and each one's description is resident for the
          # whole session). `ids` is a list option, so a host appends rather than
          # replaces: programs.ai.skills.softaworks.ids = ["react-dev"];
          #   backend-to-frontend-handoff-docs  frontend-to-backend-requirements
          #   database-schema-designer          react-dev / react-useeffect
          #   feedback-mastery                  professional-communication
          #   game-changing-features            humanizer
        };
        # systems = {
        #   name = "systems";
        #   input = "wshobson-agents";
        #   subdir = "plugins/systems-programming/skills";
        #   ids = [
        #     "memory-safety-patterns"
        #   ];
        # };
        local = {
          path = ./content;
          ids = [
            "caveman"
            "nix-coding"
            "property-based-testing"
            "python-simplifier"
            "typescript-simplifier"
          ];
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
