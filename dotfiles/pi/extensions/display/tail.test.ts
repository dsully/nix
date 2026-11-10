import { expect, test } from "bun:test";
import { callLabel, codemodeHead, glyphOf, OWN_TOOLS } from "./call.js";
import { codemodeBashCommand, codemodeCallsSummary } from "./codemode.js";
import { editStat, formatDuration, resultTail } from "./tail.js";

const cwd = "/repo";

test("paths inside cwd are relative, outside stay absolute", () => {
  expect(callLabel("read", { path: "/repo/src/a.ts" }, cwd)).toBe("src/a.ts");
  expect(callLabel("read", { path: "/etc/hosts" }, cwd)).toBe("/etc/hosts");
});

test("read shows its line range", () => {
  expect(callLabel("read", { path: "/repo/a.ts", offset: 10, limit: 5 }, cwd)).toBe("a.ts:10-14");
});

test("mcp tools read as server/tool with their first text argument", () => {
  expect(callLabel("mcp__gortex__search", { query: "foo\nbar" }, cwd)).toBe("gortex/search foo");
});

test("codemode shows its first code line, not the options directive", () => {
  expect(codemodeHead('// @options: {"timeout_ms": 1}\n\nconst x = await tools.read({})')).toBe(
    "const x = await tools.read({})",
  );
});

test("every drawn tool has its own glyph; unknown tools share a fallback", () => {
  for (const name of OWN_TOOLS) expect(glyphOf(name)).not.toBe(glyphOf("some_custom_tool"));
});

test("codemode summary counts each tool once and lists distinct bash commands", () => {
  const calls = [
    { name: "bash", args: '{"command":"git status"}' },
    { name: "read", args: "{}" },
    { name: "bash", args: '{"command":"npm test"}' },
    { name: "read", args: "{}" },
    { name: "bash", args: '{"command":"git status"}' },
  ];
  const summary = codemodeCallsSummary(calls)!;
  expect(summary).toContain("bash ×3 git status");
  expect(summary).toContain("bash npm test");
  expect(summary).toContain("read ×2");
  expect(summary.match(/git status/g)).toHaveLength(1);
});

test("a command cut inside its JSON preview keeps an ellipsis", () => {
  expect(codemodeBashCommand('{"command":"echo \\"hi\\" && ls -la /very/long...')).toEndWith("…");
});

test("a running row shows its latest output line and elapsed time", () => {
  const tail = resultTail({ toolName: "bash", text: "one\ntwo\n", isError: false, isPartial: true, elapsedMs: 3200 });
  expect(tail.text).toBe("two");
  expect(tail.suffix).toBe(formatDuration(3200));
});

test("a failed tool shows its first error line", () => {
  const tail = resultTail({ toolName: "read", text: "\nboom\nmore", isError: true, isPartial: false });
  expect(tail).toMatchObject({ text: "boom", tone: "error" });
});

test("a failed command shows its exit code and last output line", () => {
  const text = "building\nFAIL src/a.test.ts\n\nCommand exited with code 2";
  expect(resultTail({ toolName: "bash", text, isError: true, isPartial: false }).text).toBe(
    "exit 2 · FAIL src/a.test.ts",
  );
  expect(
    resultTail({ toolName: "bash", text: "(no output)\n\nCommand exited with code 1", isError: true, isPartial: false })
      .text,
  ).toBe("exit 1");
});

test("short calls get no duration", () => {
  expect(
    resultTail({ toolName: "bash", text: "x", isError: false, isPartial: false, durationMs: 40 }).suffix,
  ).toBeUndefined();
});

test("grep reports matches and files from its metrics", () => {
  const tail = resultTail({
    toolName: "grep",
    text: "",
    details: { metrics: { matches: 1, files: 1 } },
    isError: false,
    isPartial: false,
  });
  expect(tail.text).toBe("1 match in 1 file");
});

test("edit stats come from hashline metrics, or a counted unified diff", () => {
  expect(editStat({ metrics: { added_lines: 2, removed_lines: 1 } })).toBe("+2/-1");
  expect(editStat({ patch: "--- a\n+++ a\n@@ -1 +1 @@\n-old\n+new\n+more" })).toBe("+2/-1");
});
