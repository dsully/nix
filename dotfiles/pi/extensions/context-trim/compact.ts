export const MAX_CHARS = 6_000;
export const MAX_LINES = 120;

function cutChars(text: string): string {
  if (text.length <= MAX_CHARS) return text;
  const head = Math.floor(MAX_CHARS * 0.6);
  const tail = MAX_CHARS - head;
  return `${text.slice(0, head)}\n\n... ${text.length - head - tail} characters omitted ...\n\n${text.slice(-tail)}`;
}

/** Head/tail preview of a tool's text output, or undefined when the output is small enough to send whole. */
export function preview(text: string, isError: boolean): string | undefined {
  const lines = text.split("\n");
  if (text.length <= MAX_CHARS && lines.length <= MAX_LINES) return undefined;
  const [head, tail] = isError ? [80, 60] : [60, 40];
  if (lines.length <= head + tail) return cutChars(text);
  const omitted = lines.length - head - tail;
  return cutChars(
    [...lines.slice(0, head), "", `... ${omitted} lines omitted ...`, "", ...lines.slice(-tail)].join("\n"),
  );
}
