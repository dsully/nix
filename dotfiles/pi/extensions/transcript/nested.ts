export function nestedResultLines(text: string, expanded: boolean): string[] {
  const lines = text
    .split("\n")
    .map((line) => line.trimEnd())
    .filter((line) => line.trim());
  if (lines.length === 0) return ["(no result)"];
  const [head, ...rest] = lines;
  const shown = expanded ? rest.slice(0, 30) : rest.slice(0, 3);
  const body = shown.map((line, index) => `${index === 0 ? "  ⎿ " : "    "}${line}`);
  const more = rest.length - shown.length;
  if (more > 0) body.push(`    … ${more} more`);
  return [head ?? "(no result)", ...body];
}
