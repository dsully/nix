// From oh-my-pi packages/coding-agent/src/tools/shell-tokenize.ts (MIT, see LICENSE).

interface FlatShellCommandSegment {
  /** Original segment text with quoting and escaping preserved. */
  text: string;
  /**
   * True when this segment consumes the previous stage's stdout via an
   * unquoted `|` or `|&`. Blank and comment-only continuation lines preserve
   * the pending pipe state. `||`, `;`, `&`, and `&&` start an independent
   * command and leave this false.
   */
  pipedStdin: boolean;
}

/**
 * Returns the flat shell command segments with the original text of each, preserving quoting and escaping.
 * Declines to split (returns []) on heredocs, command substitution, backticks, grouping, and malformed quoting;
 * callers must still check the complete input in that case.
 */
export function extractFlatShellCommandSegments(command: string): FlatShellCommandSegment[] {
  const segments: FlatShellCommandSegment[] = [];
  let segmentStart = 0;
  let inSingle = false;
  let inDouble = false;
  let atWordStart = true;
  let currentPiped = false;

  const pushSegment = (end: number): boolean => {
    const segment = command.slice(segmentStart, end).trim();
    if (segment.length === 0) return false;
    segments.push({ text: segment, pipedStdin: currentPiped });
    return true;
  };

  for (let i = 0; i < command.length; i++) {
    const ch = command[i];
    if (inSingle) {
      if (ch === "'") inSingle = false;
      continue;
    }
    if (inDouble) {
      if (ch === "\\") {
        if (i + 1 >= command.length) return [];
        i++;
        continue;
      }
      if (ch === '"') {
        inDouble = false;
        continue;
      }
      if (ch === "`" || (ch === "$" && command[i + 1] === "(")) return [];
      continue;
    }

    if (ch === "'") {
      inSingle = true;
      atWordStart = false;
      continue;
    }
    if (ch === '"') {
      inDouble = true;
      atWordStart = false;
      continue;
    }
    if (ch === "\\") {
      if (i + 1 >= command.length) return [];
      i++;
      atWordStart = false;
      continue;
    }
    if (
      ch === "`" ||
      ch === "(" ||
      ch === ")" ||
      (ch === "$" && command[i + 1] === "(") ||
      (ch === "$" && command[i + 1] === "{") ||
      (ch === "<" && command[i + 1] === "<") ||
      ((ch === "{" || ch === "}") && atWordStart && (command[i + 1] === undefined || /[ \t\n;]/.test(command[i + 1])))
    ) {
      return [];
    }
    if (ch === "#" && atWordStart) {
      const pushed = pushSegment(i);
      const newline = command.indexOf("\n", i + 1);
      if (newline === -1) return segments;
      i = newline;
      segmentStart = newline + 1;
      atWordStart = true;
      // Preserve a pending pipe through a comment-only continuation.
      if (pushed) currentPiped = false;
      continue;
    }
    const isRedirectionOperatorCharacter =
      ch === "|"
        ? command[i - 1] === ">"
        : ch === "&"
          ? command[i - 1] === ">" || command[i - 1] === "<" || command[i + 1] === ">"
          : false;
    if ((ch === "\n" || ch === ";" || ch === "|" || ch === "&") && !isRedirectionOperatorCharacter) {
      const pushed = pushSegment(i);
      const doubled = (ch === "|" || ch === "&") && command[i + 1] === ch;
      const pipeStderr = ch === "|" && command[i + 1] === "&";
      if (doubled || pipeStderr) i++;
      // `|` and `|&` pipe into the next segment. Blank continuation lines preserve that pending state.
      if (pushed || ch !== "\n") currentPiped = ch === "|" && !doubled;
      segmentStart = i + 1;
      atWordStart = true;
      continue;
    }
    atWordStart = ch === " " || ch === "\t";
  }

  if (inSingle || inDouble) return [];
  pushSegment(command.length);
  return segments;
}
