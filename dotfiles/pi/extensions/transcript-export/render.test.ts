import { expect, test } from "bun:test";
import { defaultName } from "./index.js";
import { inline, markdownToHtml } from "./markdown.js";
import { activityLabel, clip, fence, infoOf, segments, toHtml, toMarkdown, turnsOf } from "./render.js";

const header = { type: "session", id: "s1", cwd: "/tmp/project", timestamp: "2026-01-01T00:00:00.000Z" };
const entries = [
  {
    type: "message",
    id: "u1",
    timestamp: "2026-01-01T00:00:01.000Z",
    message: { role: "user", content: "List <files> & go" },
  },
  {
    type: "message",
    id: "a1",
    message: {
      role: "assistant",
      model: "claude",
      content: [
        { type: "thinking", thinking: "Look first." },
        { type: "toolCall", id: "c1", name: "bash", arguments: { command: "ls" } },
      ],
    },
  },
  {
    type: "message",
    id: "r1",
    message: {
      role: "toolResult",
      toolCallId: "c1",
      isError: true,
      durationMs: 72,
      content: [{ type: "text", text: "<script>x</script>" }],
    },
  },
  {
    type: "message",
    id: "a2",
    timestamp: "2026-01-01T00:00:04.000Z",
    message: {
      role: "assistant",
      content: [{ type: "text", text: "Done. [bad](javascript:alert(1)) [ok](https://x.dev) <b>raw</b>" }],
    },
  },
];

test("tool results attach to their calls and assistant messages group into one turn", () => {
  const turns = turnsOf(entries);
  expect(turns.map((t) => t.role)).toEqual(["user", "assistant"]);
  const [first] = segments(turns[1].parts);
  expect(first.kind).toBe("activity");
  if (first.kind !== "activity") return;
  const tool = first.parts[1];
  expect(tool.kind === "tool" && tool.tool.result === "<script>x</script>" && tool.tool.isError).toBe(true);
  expect(activityLabel(first.parts)).toEqual(["2 steps", "bash", "1 thought", "1 failed"]);
});

test("session info falls back to the first prompt and counts prompts on the branch", () => {
  const info = infoOf(header, entries, undefined, turnsOf(entries));
  expect(info).toMatchObject({ title: "List <files> & go", model: "claude", prompts: 1, id: "s1" });
  expect(infoOf(header, entries, "  Named ", []).title).toBe("Named");
});

test("html escapes session text and drops unsafe links", () => {
  const turns = turnsOf(entries);
  const html = toHtml(infoOf(header, entries, undefined, turns), turns);
  expect(html).not.toContain("<script>");
  expect(html).toContain("&lt;script&gt;x&lt;/script&gt;");
  expect(html).toContain("List &lt;files&gt; &amp; go");
  expect(html).not.toContain("javascript:");
  expect(html).toContain('<a href="https://x.dev">ok</a>');
  expect(html).not.toContain("<b>raw</b>");
  expect(html).toContain('class="tool error"');
});

test("markdown folds tools into details with an escaped summary", () => {
  const turns = turnsOf(entries);
  const md = toMarkdown(infoOf(header, entries, undefined, turns), turns);
  expect(md.startsWith("# List <files> & go\n")).toBe(true);
  expect(md).toContain("<summary><code>bash</code> ls · 72 ms · failed</summary>");
  expect(fence("a ```` b", "")).toBe("`````\na ```` b\n`````");
});

test("clipping notes what was cut", () => {
  const long = Array.from({ length: 130 }, (_, i) => String(i + 1)).join("\n");
  expect(clip(long).note).toBe("10 more lines");
  expect(clip(long).text.endsWith("\n120")).toBe(true);
  expect(clip("short\n\n")).toEqual({ text: "short", note: undefined });
});

test("markdown blocks: fences, headings, nested lists, quotes, tables", () => {
  expect(markdownToHtml("```swift\nlet a = 1 < 2\n```")).toBe(
    '<figure class="code"><figcaption>swift</figcaption><pre><code>let a = 1 &lt; 2</code></pre></figure>',
  );
  expect(markdownToHtml("# Title")).toBe("<h3>Title</h3>");
  expect(markdownToHtml("- a\n  - b\n- c")).toBe("<ul><li>a\n<ul><li>b</li></ul></li><li>c</li></ul>");
  expect(markdownToHtml("3. x\n4. y")).toBe('<ol start="3"><li>x</li><li>y</li></ol>');
  expect(markdownToHtml("> quoted\n> more")).toBe("<blockquote><p>quoted\nmore</p></blockquote>");
  expect(markdownToHtml("| a | b |\n|---|:-:|\n| 1 | `|` |")).toContain("<td>1</td>");
  expect(markdownToHtml("one\n\ntwo")).toBe("<p>one</p>\n<p>two</p>");
});

test("inline styles leave code and snake_case alone", () => {
  expect(inline("**bold** *em* ~~del~~ `a*b*c`")).toBe(
    "<strong>bold</strong> <em>em</em> <del>del</del> <code>a*b*c</code>",
  );
  expect(inline("snake_case_name stays")).toBe("snake_case_name stays");
  expect(inline("[`code` link](https://a.b)")).toBe('<a href="https://a.b"><code>code</code> link</a>');
  expect(inline("see https://a.b/c.")).toBe('see <a href="https://a.b/c">https://a.b/c</a>.');
});

test("default file names drop path separators", () => {
  expect(defaultName("Fix a/b: now", "html")).toBe("Fix a-b- now.html");
  expect(defaultName("  ", "md")).toBe("session.md");
});
