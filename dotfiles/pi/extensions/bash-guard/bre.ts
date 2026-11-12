// The grep tool rejects patterns that are not valid unicode-mode JS RegExps but matches with Rust regex
// semantics (`[a&&b]` is an intersection), so output stays inside the syntax both read the same way.

type Previous = "start" | "caret" | "atom" | "other";

const KEPT_ESCAPES = new Set("\\.*[]^$wWsS");

function bracket(pattern: string, start: number): { text: string; end: number } | undefined {
  let i = start + 1;
  let text = "[";
  if (pattern[i] === "^") text += pattern[i++];
  if (pattern[i] === "]") {
    text += "\\]";
    i++;
  }
  for (; i < pattern.length; i++) {
    const ch = pattern[i];
    if (ch === "]") return { text: `${text}]`, end: i };
    if (/^\[[:.=]/.test(pattern.slice(i))) return undefined;
    if ((ch === "&" || ch === "~" || ch === "-") && pattern[i + 1] === ch) return undefined;
    text += ch === "\\" || ch === "[" ? `\\${ch}` : ch;
  }
  return undefined;
}

/** Converts a GNU grep basic regex to the grep tool's syntax; undefined for constructs it cannot map. */
export function breToRegex(pattern: string): string | undefined {
  let out = "";
  let previous: Previous = "start";
  for (let i = 0; i < pattern.length; i++) {
    const ch = pattern[i];
    if (ch === "\\") {
      const next = pattern[++i];
      if (next === undefined) return undefined;
      if (next === "(" || next === "|") {
        out += next;
        previous = "start";
      } else if (next === ")") {
        out += next;
        previous = "atom";
      } else if (next === "+" || next === "?") {
        if (previous !== "atom") return undefined;
        out += next;
        previous = "other";
      } else if (next === "{") {
        const interval = /^(\d+(?:,\d*)?)\\\}/.exec(pattern.slice(i + 1));
        if (!interval || previous !== "atom") return undefined;
        out += `{${interval[1]}}`;
        i += interval[0].length;
        previous = "other";
      } else if (next === "b" || next === "B") {
        out += `\\${next}`;
        previous = "other";
      } else if (next === "/") {
        out += next;
        previous = "atom";
      } else if (KEPT_ESCAPES.has(next)) {
        out += `\\${next}`;
        previous = "atom";
      } else return undefined;
    } else if (ch === "[") {
      const set = bracket(pattern, i);
      if (!set) return undefined;
      out += set.text;
      i = set.end;
      previous = "atom";
    } else if (ch === "*") {
      if (previous === "atom") {
        out += ch;
        previous = "other";
      } else if (previous === "start" || previous === "caret") {
        out += "\\*";
        previous = "atom";
      } else return undefined;
    } else if (ch === "^") {
      out += previous === "start" ? ch : "\\^";
      previous = previous === "start" ? "caret" : "atom";
    } else if (ch === "$") {
      const anchors = i === pattern.length - 1 || pattern.startsWith("\\)", i + 1) || pattern.startsWith("\\|", i + 1);
      out += anchors ? ch : "\\$";
      previous = anchors ? "other" : "atom";
    } else {
      out += "|+?(){}".includes(ch) ? `\\${ch}` : ch;
      previous = "atom";
    }
  }
  return out;
}
