{lib}: let
  # Turn a marketplace's curated plugin selection into agent-skills `sources`
  # plus the per-source `enableAll` list, capturing every skill a plugin ships
  # (the Claude `plugin@marketplace` model). Each selected plugin becomes one
  # source pointing at its skills subdir, namespaced with `idPrefix = name` so
  # catalog IDs read `<name>/<skill>` (e.g. foo/bugs). Note: idPrefix
  # only affects the nix catalog ID and on-disk path; the agent still invokes a
  # skill by its SKILL.md frontmatter `name:`.
  #
  #   skillSourcesFrom {
  #     name = "foo";
  #     input = "foo-skills";  # agent-skills source `input` ref
  #     select = ["audit"];    # plugin names under plugins/<p>/skills
  #   }
  #   => {
  #     sources.foo-audit = { input = "foo-skills"; subdir = "plugins/audit/skills"; idPrefix = "foo"; };
  #     enableAll = ["foo-audit"];
  #   }
  #
  # `input` (string) and `src` (path) are mutually exclusive; pass whichever the
  # agent-skills source should reference.
  skillSourcesFrom = {
    name,
    select,
    input ? null,
    src ? null,
  }: let
    base =
      if input != null
      then {inherit input;}
      else {path = src;};

    sourceName = plugin: "${name}-${plugin}";

    sources = lib.listToAttrs (map (
        plugin:
          lib.nameValuePair (sourceName plugin) (base
            // {
              subdir = "plugins/${plugin}/skills";
              idPrefix = name;
            })
      )
      select);

    enableAll = map sourceName select;
  in {
    inherit sources enableAll;
  };
in {
  inherit skillSourcesFrom;
}
