export function thoughtToolRows(children: readonly unknown[]): Map<object, boolean> {
  const grouped: object[] = [];
  const result = new Map<object, boolean>();
  let thought = false;

  const flush = () => {
    grouped.forEach((row, index) => result.set(row, index === grouped.length - 1));
    grouped.length = 0;
  };

  for (const child of children) {
    if (!child || typeof child !== "object") {
      flush();
      thought = false;
      continue;
    }
    if ("hiddenThinkingLabel" in child) {
      flush();
      const label = (child as { hiddenThinkingLabel?: unknown }).hiddenThinkingLabel;
      thought = typeof label === "string" && label.startsWith("│ * Thought:");
    } else if ("toolName" in child) {
      if (thought) grouped.push(child);
      else flush();
    } else {
      flush();
      thought = false;
    }
  }

  flush();
  return result;
}
