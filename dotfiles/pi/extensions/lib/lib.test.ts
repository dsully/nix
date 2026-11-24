import { appendFileSync, mkdirSync, mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { expect, test } from "bun:test";
import { gitRoot } from "./git-root.js";
import { patchMethod } from "./patch.js";
import { textOf } from "./text.js";
import { field } from "./field.js";
import { exitCode } from "./rex.js";
import { follow } from "./follow.js";

test("git root is found from a subdirectory, and is undefined outside a repo", () => {
  const dir = mkdtempSync(join(tmpdir(), "lib-git-root-"));
  mkdirSync(join(dir, "repo", ".git"), { recursive: true });
  mkdirSync(join(dir, "repo", "a", "b"), { recursive: true });
  expect(gitRoot(join(dir, "repo", "a", "b"))).toBe(join(dir, "repo"));
  expect(gitRoot(dir)).toBeUndefined();
});

test("textOf joins only non-empty text parts", () => {
  expect(textOf("plain")).toBe("plain");
  expect(
    textOf([{ type: "text", text: "a" }, { type: "image" }, { type: "text", text: "" }, { type: "text", text: "b" }]),
  ).toBe("a\nb");
  expect(textOf(undefined)).toBe("");
});

test("reinstalling a patch replaces it instead of stacking, and restore undoes it", () => {
  class Target {
    greet() {
      return "hi";
    }
  }
  const install = (suffix: string) =>
    patchMethod<() => string>(Target.prototype, "greet", "test.lib.greet", (original) =>
      original
        ? function (this: Target) {
            return original.call(this) + suffix;
          }
        : undefined,
    );
  install("!");
  const restore = install("?");
  expect(new Target().greet()).toBe("hi?");
  restore();
  expect(new Target().greet()).toBe("hi");
});

test("restore deletes a method the target did not own", () => {
  const target: { handle?: () => string } = {};
  const restore = patchMethod<() => string>(target, "handle", "test.lib.handle", () => () => "patched");
  expect(target.handle?.()).toBe("patched");
  restore();
  expect(Object.hasOwn(target, "handle")).toBe(false);
});

test("a wrap that returns undefined leaves the method alone", () => {
  const target = { run: () => 1 };
  patchMethod(target, "run", "test.lib.run", () => undefined);
  expect(target.run()).toBe(1);
});

test("field reads a value, and a field whose getter throws as undefined", () => {
  const message = new Proxy({ usage: 1 } as { usage: number; responseId?: string }, {
    get(target, key) {
      if (key === "responseId") throw new Error("unsupported_feature");
      return Reflect.get(target, key);
    },
  });
  expect(field(() => message.usage)).toBe(1);
  expect(field(() => message.responseId)).toBeUndefined();
});

test("exitCode reads rex wait's exit_code, and is undefined when the pane closed first", () => {
  expect(exitCode('{"exit_code":0}\n')).toBe(0);
  expect(exitCode('{"exit_code":3}')).toBe(3);
  expect(exitCode('{"block_closed":true}')).toBeUndefined();
  expect(exitCode("")).toBeUndefined();
});

test("follow skips bytes before from, waits for a missing file, and delivers the rest on stop", () => {
  const path = join(mkdtempSync(join(tmpdir(), "lib-follow-")), "log");
  const seen: string[] = [];
  const stop = follow(path, 4, (d) => seen.push(d.toString()));
  writeFileSync(path, "old new");
  appendFileSync(path, " more");
  stop();
  expect(seen.join("")).toBe("new more");
});
