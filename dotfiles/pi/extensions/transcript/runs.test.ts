import { expect, test } from "bun:test";
import { classifyShell, lookKind, runSummary, Runs } from "./runs.js";

test("commands that only look around fold, by what they do", () => {
  expect(classifyShell("rg foo src | head -5")).toBe("search");
  expect(classifyShell("cat a.ts 2>/dev/null")).toBe("read");
  expect(classifyShell("cd sub && ls -la")).toBe("list");
  expect(classifyShell("git log --oneline -5")).toBe("read");
});

test("commands that write or run never fold", () => {
  for (const command of [
    "rm -rf x",
    "cat a > b",
    "sed -i s/a/b/ f",
    "find . -delete",
    "git commit -m x",
    "npm test",
    "ls $(pwd)",
    "fd -x rm",
  ]) {
    expect(classifyShell(command)).toBeUndefined();
  }
});

test("only look-around tools have a kind", () => {
  expect(lookKind("read", {})).toBe("read");
  expect(lookKind("bash", { command: "rg x" })).toBe("search");
  expect(lookKind("edit", { path: "a" })).toBeUndefined();
  expect(lookKind("bash", { command: "make" })).toBeUndefined();
});

test("calls join the current run until it ends", () => {
  const runs = new Runs();
  const first = runs.add({ id: "a", kind: "read", label: "a" }, 0);
  expect(runs.add({ id: "b", kind: "search", label: "b" }, 1)).toBe(first);
  runs.end();
  const next = runs.add({ id: "c", kind: "read", label: "c" }, 2);
  expect(next).not.toBe(first);
  expect(runs.get("b")).toBe(first);
});

test("adding a known call again keeps its run", () => {
  const runs = new Runs();
  const run = runs.add({ id: "a", kind: "read", label: "a" }, 0);
  runs.end();
  expect(runs.add({ id: "a", kind: "read", label: "a" }, 1)).toBe(run);
  expect(run.members).toHaveLength(1);
});

test("finish records failure on the member", () => {
  const runs = new Runs();
  runs.add({ id: "a", kind: "read", label: "a" }, 0);
  expect(runs.finish("a", true)?.members[0]).toMatchObject({ done: true, error: true });
});

test("summary counts each kind, in the running or the done form", () => {
  const members = [
    { id: "a", kind: "read" as const, label: "", done: true, error: false },
    { id: "b", kind: "read" as const, label: "", done: true, error: false },
    { id: "c", kind: "search" as const, label: "", done: true, error: false },
  ];
  expect(runSummary(members, false)).toBe("Read 2 files, searched 1 pattern");
  expect(runSummary(members, true)).toStartWith("Reading 2 files");
});
