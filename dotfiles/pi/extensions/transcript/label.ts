export type Part = { kind: string; hidden?: boolean };
export type ThinkingBlock = { type?: string; thinking?: string };

const MAX_LABEL = 100;

export function thinkingLine(content: readonly ThinkingBlock[] | undefined): string | undefined {
  for (const block of content ?? []) {
    if (block.type !== "thinking") continue;
    const line = block.thinking
      ?.split("\n")
      .map((part) => part.trim())
      .find(Boolean);
    if (!line) continue;
    return line.length > MAX_LABEL ? `${line.slice(0, MAX_LABEL - 1)}…` : line;
  }
  return undefined;
}

export function collapseThinking<T extends Part>(parts: T[]): T[] {
  let last = -1;
  for (let index = 0; index < parts.length; index++) {
    if (parts[index]?.kind === "thinking" && parts[index]?.hidden) last = index;
  }
  if (last < 0) return parts;
  const kept: T[] = [];
  for (let index = 0; index < parts.length; index++) {
    const part = parts[index];
    if (!part) continue;
    if (part.kind === "thinking" && part.hidden && index !== last) continue;
    if (part.kind === "spacer" && kept.at(-1)?.kind === "spacer") continue;
    kept.push(part);
  }
  if (kept[0]?.kind === "spacer") kept.shift();
  return kept;
}

export function presentThought(current: string | undefined, line: string | undefined): string | undefined {
  if (!line || !current || /Thinking/.test(current)) return undefined;
  const duration = current.match(/· \d+(?:\.\d+)?s$/)?.[0];
  return `│ * Thought: ${line}${duration ? ` ${duration}` : ""}`;
}
