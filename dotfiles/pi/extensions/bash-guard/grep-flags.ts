const LEADING_IGNORE_CASE = /^\(\?i\)(?=.)/s;

/** ripgrep accepts a leading `(?i)`, but the grep tool validates patterns as JavaScript regexes, which reject it. */
export function applyInlineFlags(input: Record<string, unknown>): void {
  if (input.literal === true || typeof input.pattern !== "string") return;
  if (!LEADING_IGNORE_CASE.test(input.pattern)) return;
  input.pattern = input.pattern.replace(LEADING_IGNORE_CASE, "");
  input.ignoreCase = true;
}

/** The grep tool treats a `!` glob as a plain glob and reports no matches instead of excluding files. */
export function negatedGlobReason(input: Record<string, unknown>): string | undefined {
  if (typeof input.glob !== "string" || !input.glob.trimStart().startsWith("!")) return undefined;
  return `The grep tool cannot exclude files: glob "${input.glob}" matches nothing. Narrow \`path\` or use a positive glob, or run shell \`rg -g '${input.glob.trim()}'\`.`;
}
