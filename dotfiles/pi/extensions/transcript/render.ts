import { truncateToWidth } from "@earendil-works/pi-tui";
import { nestedResultLines } from "./nested.js";

type Theme = { fg: (color: string, text: string) => string };
type Result = { content?: { type?: string; text?: string }[] };

function resultText(result: Result): string {
  return (result.content ?? []).flatMap((part) => (part.type === "text" && part.text ? [part.text] : [])).join("\n");
}

/** Collapsed subagent result/steer: a head line plus nested detail, not the full dump and not one JSON row. */
export function nestedResultRenderer(
  result: Result,
  options: { expanded?: boolean },
  theme: Theme,
): { invalidate: () => void; render: (width: number) => string[] } {
  const lines = nestedResultLines(resultText(result), options.expanded === true);
  return {
    invalidate() {},
    render: (width: number) => lines.map((line) => truncateToWidth(theme.fg("dim", line), width)),
  };
}
