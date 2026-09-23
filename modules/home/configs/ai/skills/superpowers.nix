{
  config,
  inputs,
  lib,
  ...
}: let
  cfg = config.programs.ai.superpowers;

  # Superpowers ships a flat skills/ dir; discover ids so new upstream skills
  # register automatically.
  skillIds = builtins.attrNames (
    lib.filterAttrs (_: t: t == "directory")
    (builtins.readDir "${inputs.superpowers}/skills")
  );

  # opencode's plugin (opencode.nix) already registers these skills directly,
  # so it must never appear here — doing both would install every skill twice
  # in opencode's discovery dir and warn at startup.
  agents = lib.subtractLists ["opencode"] (lib.unique cfg.agents);
  otherAgents = lib.subtractLists ["pi"] agents;

  # pi-superagents drives these via /sp-* and finds them by frontmatter name, so pi
  # gets copies hidden from the model's skill list (saves prompt tokens every turn).
  hideFromModel = {original, ...}:
    assert lib.hasPrefix "---\n" original;
      "---\ndisable-model-invocation: true\n" + lib.removePrefix "---\n" original;
in {
  options.programs.ai.superpowers.agents = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [];
    description = ''
      agent-skills target names that receive the superpowers skills. Each
      harness appends its own target from inside its enable guard, so
      membership tracks that harness's enable state.
    '';
    example = ["claude" "codex" "pi"];
  };

  config = lib.mkIf (agents != []) {
    programs.agent-skills = {
      sources.superpowers = {
        input = "superpowers";
        subdir = "skills";
      };
      skills.explicit =
        lib.optionalAttrs (otherAgents != []) (lib.genAttrs skillIds (id: {
          from = "superpowers";
          path = id;
          agents = otherAgents;
        }))
        // lib.optionalAttrs (lib.elem "pi" agents) (lib.listToAttrs (map (id:
          lib.nameValuePair "pi-${id}" {
            from = "superpowers";
            path = id;
            agents = ["pi"];
            transform = hideFromModel;
          })
        skillIds));
    };
  };
}
