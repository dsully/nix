/** The text parts of a message's `content` (a string, or an array of typed parts), joined by `separator`. */
export function textOf(content: unknown, separator = "\n"): string {
  if (typeof content === "string") return content;
  if (!Array.isArray(content)) return "";
  return content
    .flatMap((part) => (part?.type === "text" && typeof part.text === "string" && part.text ? [part.text] : []))
    .join(separator);
}
