import { truncateToWidth } from "@earendil-works/pi-tui";
import { textOf } from "../lib/text.js";
import { nestedResultLines } from "./nested.js";

type Theme = { fg: (color: string, text: string) => string };
type Result = { content?: { type?: string; text?: string }[] };

/** Collapsed subagent result/steer: a head line plus nested detail, not the full dump and not one JSON row. */
export function nestedResultRenderer(
  result: Result,
  options: { expanded?: boolean },
  theme: Theme,
): { invalidate: () => void; render: (width: number) => string[] } {
  const lines = nestedResultLines(textOf(result.content), options.expanded === true);
  return {
    invalidate() {},
    render: (width: number) => lines.map((line) => truncateToWidth(theme.fg("dim", line), width)),
  };
}
