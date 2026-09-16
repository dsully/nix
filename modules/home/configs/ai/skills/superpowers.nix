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
      skills.explicit = lib.genAttrs skillIds (id: {
        from = "superpowers";
        path = id;
        inherit agents;
      });
    };
  };
}
