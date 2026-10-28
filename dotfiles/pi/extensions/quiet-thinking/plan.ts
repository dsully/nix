export type Part = { kind: string; hidden?: boolean };

/** Removes collapsed thinking parts from an AssistantMessageComponent plan, plus the spacers they leave behind. */
export function dropHiddenThinking<T extends Part>(parts: T[]): T[] {
  const kept: T[] = [];
  for (const part of parts) {
    if (part.kind === "thinking" && part.hidden) continue;
    if (part.kind === "spacer" && kept.at(-1)?.kind === "spacer") continue;
    kept.push(part);
  }
  if (kept[0]?.kind === "spacer" && !kept.some((p) => p.kind === "text" || p.kind === "thinking")) kept.shift();
  return kept;
}
