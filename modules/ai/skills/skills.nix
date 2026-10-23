{
  mkUserModule,
  config,
  hideFromModel,
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
      manual = lib.mkOption {
        type = lib.types.either lib.types.bool (lib.types.listOf lib.types.str);
        default = [];
        description = "Skill IDs to install hidden from the model, loadable only via an explicit /skill:<name>. `true` applies to every skill the group selects.";
      };
    };
  };

  inherit (config.programs.agent-skills) catalog;

  manualIds = key: g:
    if g.manual == true
    then
      if g.all
      then lib.attrNames (lib.filterAttrs (_: s: s.source == srcName key g) catalog)
      else g.ids
    else if g.manual == false
    then []
    else g.manual;

  superpowers = import ./superpowers.nix {inherit config hideFromModel inputs lib;};
in
  mkUserModule {
    name = "skills";
    default = false;

    # Toggleable skill groups. Each group owns one agent-skills source plus its
    # selection, so enabling/disabling a group (e.g. `programs.ai.skills.python`)
    # registers/removes the source and its skills together — agent-skills stays
    # the single source of truth, fanning out to every tool + the derived slash
    # commands (see commands.nix).
    homeOptions = lib.recursiveUpdate superpowers.options {
      programs.ai.skills = lib.mkOption {
        type = lib.types.attrsOf groupType;
        default = {};
        description = "Named, individually toggleable skill groups.";
      };
    };

    home = lib.mkMerge [
      superpowers.config

      {
        programs.agent-skills = {
          enable = true;
        };

        programs.ai.skills = {
          improve = {
            enable = lib.mkDefault false;
            input = "improve";
            subdir = "skills";
            all = true;
          };
          essentials = {
            enable = lib.mkDefault false;
            input = "wshobson-agents";
            subdir = "plugins/developer-essentials/skills";
            ids = [
              "error-handling-patterns"
            ];
          };
          # mattpocock/skills (MIT) nests skills one level deep, and a source takes
          # a single `subdir`, so each category is its own group. Only skills that
          # need no per-repo scaffolding are selected: everything under `triage`,
          # `to-tickets`, `to-spec`, `wayfinder`, `ask-matt`, and `code-review`
          # expects `docs/agents/issue-tracker.md` from that repo's
          # `setup-matt-pocock-skills`, and the `misc` + `in-progress` categories
          # are TypeScript/husky-specific or unstable upstream.
          #
          # Append per-host from the same categories with e.g.
          # `programs.ai.skills.mattpocock-engineering.ids = ["diagnosing-bugs"];`
          # (also available: prototype, improve-codebase-architecture, wizard).
          mattpocock-engineering = {
            enable = lib.mkDefault false;
            input = "mattpocock-skills";
            subdir = "skills/engineering";
            ids = [
              "codebase-design"
              # "resolving-merge-conflicts"
            ];
          };
          mattpocock-productivity = {
            input = "mattpocock-skills";
            subdir = "skills/productivity";
            manual = true;
            ids = [
              "grilling"
              # "writing-for-agents"
            ];
          };
          writing = {
            enable = lib.mkDefault false;
            input = "no-ai-slop";
            subdir = "skills";
            ids = ["no-ai-slop"];
          };
          # Every enabled skill's description sits in the system prompt for the
          # whole session, so a group is only worth carrying globally if it fires
          # on most repos. Language/framework groups are opt-in: turn them on in
          # the host or user config when working in that stack.
          python = {
            enable = lib.mkDefault false;
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
          # Only skills that fire on most repos live here. The rest
          # (property-based-testing, python-simplifier, typescript-simplifier)
          # stay in ./content unselected; enable them where they apply with
          # `programs.ai.skills.local.ids = ["python-simplifier"];` — list
          # options merge, so the host config appends to this set.
          local = {
            path = ./content;
            ids = [
              # "delegate-first"
              "remove-ai-slop"
            ];
            manual = [
              "cleanup"
              "comment-sicko"
              "dead-code-finder"
              "prompt-optimizer"
              "visual-explainer"
            ];
          };
        };
      }

      (lib.mkIf (enabled != {}) {
        assertions = lib.concatLists (lib.mapAttrsToList (name: g: [
            {
              assertion = (g.input != null) != (g.path != null);
              message = "programs.ai.skills.${name}: set exactly one of `input` or `path`.";
            }
            {
              assertion = !(g.all && lib.isList g.manual && g.manual != []);
              message = "programs.ai.skills.${name}: `all` already installs every skill, so a `manual` list would collide with it; use `manual = true`.";
            }
          ])
          enabled);

        programs.agent-skills = {
          sources = lib.mapAttrs' (key: g: lib.nameValuePair (srcName key g) (sourceOf g)) enabled;
          skills = {
            enable = lib.concatMap (g: lib.optionals (g.manual != true) g.ids) (lib.attrValues enabled);
            enableAll = lib.mapAttrsToList srcName (lib.filterAttrs (_: g: g.all && g.manual != true) enabled);
            # Allowlisted skills can't be transformed, so manual ones go in as explicit entries.
            explicit = lib.concatMapAttrs (key: g:
              lib.genAttrs (manualIds key g) (id: let
                skill = catalog.${id} or (throw "programs.ai.skills.${key}: manual skill `${id}` is not in source `${srcName key g}`.");
              in {
                from = skill.source;
                path =
                  if skill.relPath == ""
                  then "."
                  else skill.relPath;
                transform = hideFromModel;
              }))
            enabled;
          };
        };
      })

      # Nix skills go only into the nix working tree; home.file can't target outside $HOME (e.g. root's extra config).
      (let
        flake = toString config.programs.nh.flake;
        prefix = "${config.home.homeDirectory}/";
        tree = lib.removePrefix prefix flake;
      in
        lib.mkIf (lib.hasPrefix prefix flake) {
          home.file = lib.genAttrs ["${tree}/.agents/skills" "${tree}/.claude/skills"] (_: {
            source = ./nix;
            recursive = true;
          });
        })
    ];
  }
