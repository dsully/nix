import type { Translation } from "./translate.js";

type Content = { type: string; text?: string }[];
export type Outcome<C extends Content = Content> = { result: { content: C; details?: unknown }; isError: boolean };

const matchCount = (outcome: Outcome): number =>
  Number((outcome.result.details as { metrics?: { matches?: unknown } } | undefined)?.metrics?.matches ?? 0);

const joinText = (parts: Content): Content =>
  parts.every((part) => part.type === "text")
    ? [{ type: "text", text: parts.map((part) => part.text).join("\n") }]
    : parts;
/** Runs the translation, once per path when it has several, spending `totalLimit` across the runs in order. */
export async function runNative<C extends Content>(
  translation: Translation,
  args: Translation["args"],
  run: (tool: string, args: Translation["args"]) => Promise<Outcome<C>>,
): Promise<{ content: C; isError: boolean }> {
  if (!translation.paths) {
    const outcome = await run(translation.tool, args);
    return { content: outcome.result.content, isError: outcome.isError };
  }
  const outcomes: Outcome<C>[] = [];
  let remaining = translation.totalLimit ?? Number.POSITIVE_INFINITY;
  for (const path of translation.paths) {
    if (remaining <= 0) break;
    const limit = Math.min(typeof args.limit === "number" ? args.limit : Number.POSITIVE_INFINITY, remaining);
    const outcome = await run(translation.tool, Number.isFinite(limit) ? { ...args, path, limit } : { ...args, path });
    outcomes.push(outcome);
    remaining -= matchCount(outcome);
  }
  const shown = outcomes.filter((outcome) => outcome.isError || matchCount(outcome) > 0);
  return {
    content: joinText(
      (shown.length > 0 ? shown : outcomes.slice(0, 1)).flatMap((outcome) => outcome.result.content),
    ) as C,
    isError: outcomes.every((outcome) => outcome.isError),
  };
}
