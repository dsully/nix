# agent-skills transform: pi and Claude Code drop skills with this flag from the
# model's skill list; an explicit /skill:<name> still loads them.
{lib}: {original, ...}:
assert lib.hasPrefix "---\n" original; let
  parts = lib.splitString "\n---" (lib.removePrefix "---\n" original);
  # Upstream may already set the key; a duplicate YAML key makes pi reject the skill.
  frontmatter = lib.filter (line: !lib.hasPrefix "disable-model-invocation:" line) (lib.splitString "\n" (lib.head parts));
in
  lib.concatStringsSep "\n" (["---" "disable-model-invocation: true"] ++ frontmatter)
  + "\n---"
  + lib.concatStringsSep "\n---" (lib.tail parts)
