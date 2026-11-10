export type DiffKind = "add" | "del" | "ctx" | "gap";
export type Range = [start: number, end: number];
export type DiffLine = { kind: DiffKind; line?: number; text: string; marks?: Range[] };

const HUNK = /^@@ -(\d+)(?:,\d+)? \+(\d+)(?:,\d+)? @@/;

/** The new file's path from a unified diff's `+++` header, without a `b/` prefix. */
export function patchPath(patch: string): string | undefined {
  const header = patch.split("\n").find((line) => line.startsWith("+++ "));
  const path = header?.slice(4).replace(/\t.*$/, "").trim();
  if (!path || path === "/dev/null") return undefined;
  return path.replace(/^b\//, "");
}

/** Lines of a unified diff: removed lines carry their old number, the rest their new one; a gap separates hunks. */
export function parseUnified(patch: string): DiffLine[] {
  const out: DiffLine[] = [];
  let oldLine = 0;
  let newLine = 0;
  let inHunk = false;
  for (const raw of patch.replace(/\n$/, "").split("\n")) {
    const hunk = HUNK.exec(raw);
    if (hunk) {
      if (out.length) out.push({ kind: "gap", text: "" });
      oldLine = Number(hunk[1]);
      newLine = Number(hunk[2]);
      inHunk = true;
      continue;
    }
    if (!inHunk || raw.startsWith("\\")) continue;
    const text = raw.slice(1).replace(/\t/g, "   ");
    if (raw.startsWith("+")) out.push({ kind: "add", line: newLine++, text });
    else if (raw.startsWith("-")) out.push({ kind: "del", line: oldLine++, text });
    else if (raw.startsWith(" ") || raw === "") {
      out.push({ kind: "ctx", line: newLine++, text });
      oldLine++;
    } else inHunk = false;
  }
  return out;
}

const TOKEN = /\s+|\w+|[^\w\s]/g;

/** Character ranges of the tokens each side does not share, from a token-level LCS. Undefined when the lines are too long to compare. */
export function wordRanges(before: string, after: string, limit = 40_000): [Range[], Range[]] | undefined {
  const a = [...before.matchAll(TOKEN)];
  const b = [...after.matchAll(TOKEN)];
  if (a.length * b.length > limit) return undefined;
  const table = Array.from({ length: a.length + 1 }, () => new Uint16Array(b.length + 1));
  for (let i = a.length - 1; i >= 0; i--) {
    for (let j = b.length - 1; j >= 0; j--) {
      table[i]![j] = a[i]![0] === b[j]![0] ? table[i + 1]![j + 1]! + 1 : Math.max(table[i + 1]![j]!, table[i]![j + 1]!);
    }
  }
  const removed: Range[] = [];
  const added: Range[] = [];
  const push = (ranges: Range[], match: RegExpMatchArray) => {
    const start = match.index!;
    const end = start + match[0].length;
    const last = ranges.at(-1);
    if (last && last[1] === start) last[1] = end;
    else ranges.push([start, end]);
  };
  let i = 0;
  let j = 0;
  while (i < a.length || j < b.length) {
    if (i < a.length && j < b.length && a[i]![0] === b[j]![0]) {
      i++;
      j++;
    } else if (j >= b.length || (i < a.length && table[i + 1]![j]! >= table[i]![j + 1]!)) push(removed, a[i++]!);
    else push(added, b[j++]!);
  }
  return [removed, added];
}

/** Marks changed words where a block of removed lines is replaced by as many added lines. */
export function markWords(lines: DiffLine[]): DiffLine[] {
  const out = lines.map((line) => ({ ...line }));
  for (let i = 0; i < out.length;) {
    if (out[i]!.kind !== "del") {
      i++;
      continue;
    }
    let dels = i;
    while (dels < out.length && out[dels]!.kind === "del") dels++;
    let adds = dels;
    while (adds < out.length && out[adds]!.kind === "add") adds++;
    if (dels - i === adds - dels) {
      for (let k = 0; k < dels - i; k++) {
        const removed = out[i + k]!;
        const added = out[dels + k]!;
        const ranges = wordRanges(removed.text, added.text);
        // A line rewritten past recognition reads better with no marks than with every word marked.
        if (!ranges || ranges[1].reduce((sum, [s, e]) => sum + e - s, 0) > added.text.length * 0.6) continue;
        removed.marks = ranges[0];
        added.marks = ranges[1];
      }
    }
    i = Math.max(adds, i + 1);
  }
  return out;
}

/** Keeps `keep` context lines around each change, replacing the rest with gaps. */
export function trimContext(lines: DiffLine[], keep: number): DiffLine[] {
  const changed = lines.map((line) => line.kind === "add" || line.kind === "del");
  const near = (index: number) => {
    for (let d = -keep; d <= keep; d++) if (changed[index + d]) return true;
    return false;
  };
  const out: DiffLine[] = [];
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i]!;
    const kept = line.kind === "ctx" ? near(i) : line.kind !== "gap";
    if (kept) out.push(line);
    else if (out.length && out.at(-1)!.kind !== "gap") out.push({ kind: "gap", text: "" });
  }
  while (out.at(-1)?.kind === "gap") out.pop();
  return out;
}

const SGR = /\x1b\[([0-9;]*)m/y;

/** Wraps visible character ranges of an ANSI string in `open`/`close`. */
export function markRanges(ansi: string, ranges: readonly Range[], open: string, close: string): string {
  if (!ranges.length) return ansi;
  let out = "";
  let visible = 0;
  let r = 0;
  for (let i = 0; i < ansi.length;) {
    SGR.lastIndex = i;
    const sgr = SGR.exec(ansi);
    if (sgr) {
      out += sgr[0];
      i += sgr[0].length;
      continue;
    }
    while (r < ranges.length && ranges[r]![1] <= visible) r++;
    if (r < ranges.length && ranges[r]![0] === visible) out += open;
    out += ansi[i];
    i++;
    visible++;
    if (r < ranges.length && ranges[r]![1] === visible) out += close;
  }
  return out;
}

/** Puts `bg` back after every SGR that resets the background, so a band survives inner styling. */
export function keepBackground(ansi: string, bg: string): string {
  return ansi.replace(/\x1b\[([0-9;]*)m/g, (sgr, params: string) => {
    const codes = params.split(";");
    return params === "" || codes.includes("0") || codes.includes("49") ? sgr + bg : sgr;
  });
}
