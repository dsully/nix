# agent-skills transform: pi and Claude Code drop skills with this flag from the
# model's skill list; an explicit /skill:<name> still loads them.
{lib}: {original, ...}:
assert lib.hasPrefix "---\n" original;
  "---\ndisable-model-invocation: true\n" + lib.removePrefix "---\n" original
