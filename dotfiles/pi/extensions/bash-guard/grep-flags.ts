const LEADING_IGNORE_CASE = /^\(\?i\)(?=.)/s;

/** ripgrep accepts a leading `(?i)`, but the grep tool validates patterns as JavaScript regexes, which reject it. */
export function applyInlineFlags(input: Record<string, unknown>): void {
  if (input.literal === true || typeof input.pattern !== "string") return;
  if (!LEADING_IGNORE_CASE.test(input.pattern)) return;
  input.pattern = input.pattern.replace(LEADING_IGNORE_CASE, "");
  input.ignoreCase = true;
}
