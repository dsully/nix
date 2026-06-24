{lib}: let
  # Turn a marketplace's curated plugin list into `programs.ai.skills` groups:
  # one toggleable group per plugin, capturing all of that plugin's skills and
  # namespacing their IDs by `name` (idPrefix). Mirrors the upstream grouping so
  # consuming flakes declare skills the same way.
  #
  #   skillGroupsFrom {
  #     name = "apple-sear";
  #     input = "apple-sear-skills";          # agent-skills source `input` ref
  #     select = ["audit" "gh"];              # plugin names under plugins/<p>/skills
  #   }
  #   => {
  #     apple-sear-audit = { input = "apple-sear-skills"; subdir = "plugins/audit/skills"; idPrefix = "apple-sear"; all = true; };
  #     apple-sear-gh    = { input = "apple-sear-skills"; subdir = "plugins/gh/skills"; idPrefix = "apple-sear"; all = true; };
  #   }
  #
  # `input` (string) and `src` (path) are mutually exclusive.
  skillGroupsFrom = {
    name,
    select,
    input ? null,
    src ? null,
  }: let
    base =
      if input != null
      then {inherit input;}
      else {path = src;};
  in
    lib.listToAttrs (map
      (plugin:
        lib.nameValuePair "${name}-${plugin}" (base
          // {
            subdir = "plugins/${plugin}/skills";
            idPrefix = name;
            all = true;
          }))
      select);
in {
  inherit skillGroupsFrom;
}
