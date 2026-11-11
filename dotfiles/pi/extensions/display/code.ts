export type ReadRow = { kind: "code"; line: number; anchor: string; text: string } | { kind: "note"; text: string };

// pi-hashline-edit-pro serves each line as `<4 letters>│<text>`; src/hashline/hash.ts.
const ANCHORED = /^([A-Za-z]{4})│(.*)$/;

/** Hashline read output as numbered code rows and the notes around them; undefined when no row has an anchor. */
export function readRows(text: string, start: number): ReadRow[] | undefined {
  let line = start;
  const rows = text.split("\n").map((raw): ReadRow => {
    const match = ANCHORED.exec(raw);
    return match ? { kind: "code", line: line++, anchor: match[1]!, text: match[2]! } : { kind: "note", text: raw };
  });
  return rows.some((row) => row.kind === "code") ? rows : undefined;
}

export type GrepRow =
  | { kind: "file"; path: string }
  | { kind: "hit"; line: number; match: boolean; anchor?: string; text: string }
  | { kind: "note"; text: string };

// pi-hashline-edit-pro src/grep.ts displayRowsForHit: `<line>:│ <anchor>│<text>` for a match, `-│` for context.
const FILE = /^=== (.+) ===$/;
const HIT = /^\s*(\d+)([:-])│ (?:([A-Za-z]{4})│)?(.*)$/;

/** Hashline grep output as rows; undefined when no row is a hit. */
export function grepRows(text: string): GrepRow[] | undefined {
  const rows = text.split("\n").map((raw): GrepRow => {
    const file = FILE.exec(raw);
    if (file) return { kind: "file", path: file[1]! };
    const hit = HIT.exec(raw);
    if (!hit) return { kind: "note", text: raw };
    const row: GrepRow = { kind: "hit", line: Number(hit[1]), match: hit[2] === ":", text: hit[4]! };
    return hit[3] ? { ...row, anchor: hit[3] } : row;
  });
  return rows.some((row) => row.kind === "hit") ? rows : undefined;
}

type GrepArgs = { pattern?: unknown; literal?: unknown; ignoreCase?: unknown };

/** The pattern compiled the way pi-hashline-edit-pro's grep compiles it; undefined when it does not compile. */
function grepPattern(args: GrepArgs | undefined): RegExp | undefined {
  if (typeof args?.pattern !== "string" || !args.pattern) return undefined;
  const source = args.literal === true ? args.pattern.replace(/[.*+?^${}()|[\]\\]/g, "\\$&") : args.pattern;
  try {
    return new RegExp(source, args.ignoreCase === true ? "giu" : "gu");
  } catch {
    return undefined;
  }
}

/** [start, end) of each non-empty match of the grep call's pattern in `text`. */
export function matchRanges(text: string, args: GrepArgs | undefined): Array<[number, number]> {
  const pattern = grepPattern(args);
  if (!pattern) return [];
  return [...text.matchAll(pattern)].flatMap((m) =>
    m[0] ? [[m.index, m.index + m[0].length] as [number, number]] : [],
  );
}

export type ListRow = { kind: "entry"; name: string; dir: boolean } | { kind: "note"; text: string };

/** Pi's ls output, one name per line with `/` after directories; bracketed and parenthesized lines are notes. */
export function listRows(text: string): ListRow[] {
  return text
    .replace(/\n+$/, "")
    .split("\n")
    .map((raw): ListRow =>
      !raw || /^\[.*\]$|^\(.*\)$/.test(raw)
        ? { kind: "note", text: raw }
        : { kind: "entry", name: raw.replace(/\/$/, ""), dir: raw.endsWith("/") },
    );
}
