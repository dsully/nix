import { expect, test } from "bun:test";
import { type Outcome, runNative } from "./native.js";
import type { Translation } from "./translate.js";

function fakeGrep(matchesByPath: Record<string, number>) {
  const calls: Translation["args"][] = [];
  const run = async (_tool: string, args: Translation["args"]): Promise<Outcome> => {
    calls.push(args);
    const path = String(args.path);
    if (!(path in matchesByPath))
      return { result: { content: [{ type: "text", text: `${path}: not found` }] }, isError: true };
    const matches = Math.min(matchesByPath[path], typeof args.limit === "number" ? args.limit : 100);
    const text = matches > 0 ? `=== ${path} === ${matches}` : "No matches found.";
    return { result: { content: [{ type: "text", text }], details: { metrics: { matches } } }, isError: false };
  };
  return { calls, run };
}

const search = (paths: string[], extra: Partial<Translation> = {}, limit?: number): Translation => ({
  tool: "grep",
  args: limit === undefined ? { pattern: "foo" } : { pattern: "foo", limit },
  paths,
  ...extra,
});

test("searches every path and joins the results that matched", async () => {
  const { calls, run } = fakeGrep({ src: 2, apps: 0, lib: 1 });
  const translation = search(["src", "apps", "lib"]);
  const ran = await runNative(translation, translation.args, run);
  expect(calls.map((args) => args.path)).toEqual(["src", "apps", "lib"]);
  expect(calls.every((args) => args.limit === undefined)).toBe(true);
  expect(ran.content).toEqual([{ type: "text", text: "=== src === 2\n=== lib === 1" }]);
  expect(ran.isError).toBe(false);
});

test("spends the total limit across paths and stops when it runs out", async () => {
  const { calls, run } = fakeGrep({ src: 3, apps: 5, lib: 5 });
  const translation = search(["src", "apps", "lib"], { totalLimit: 5 }, 5);
  await runNative(translation, translation.args, run);
  expect(calls.map((args) => [args.path, args.limit])).toEqual([
    ["src", 5],
    ["apps", 2],
  ]);
});

test("keeps the per-path max count below the remaining total", async () => {
  const { calls, run } = fakeGrep({ "a.ts": 9, "b.ts": 9 });
  const translation = search(["a.ts", "b.ts"], { totalLimit: 3 }, 2);
  await runNative(translation, translation.args, run);
  expect(calls.map((args) => args.limit)).toEqual([2, 1]);
});

test("reports no matches once when no path matched", async () => {
  const { run } = fakeGrep({ src: 0, apps: 0 });
  const translation = search(["src", "apps"]);
  const ran = await runNative(translation, translation.args, run);
  expect(ran.content.map((part) => part.text)).toEqual(["No matches found."]);
});

test("is an error only when every path failed", async () => {
  const { run } = fakeGrep({ src: 1 });
  const some = await runNative(search(["src", "gone"]), { pattern: "foo" }, run);
  expect(some.isError).toBe(false);
  expect(some.content[0].text).toContain("gone: not found");
  const all = await runNative(search(["gone", "missing"]), { pattern: "foo" }, run);
  expect(all.isError).toBe(true);
});
