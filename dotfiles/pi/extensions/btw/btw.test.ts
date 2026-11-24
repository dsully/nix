import { expect, test } from "bun:test";
import { childArgs, readLink, titleFor } from "./thread.js";

const thread = {
  id: "12345678-1234-1234-1234-123456789abc",
  title: "Question",
  question: "@not-a-file; $(not-a-command)",
  provider: "test-provider",
  model: "test-model",
};

test("a new thread starts on its model with the question as one argument; a resumed one sends neither", () => {
  const fresh = childArgs("/d", thread, false);
  expect(fresh.slice(-6)).toEqual([
    "--provider",
    "test-provider",
    "--model",
    "test-model",
    "--",
    ` ${thread.question}`,
  ]);
  const resumed = childArgs("/d", thread, true);
  expect(resumed).not.toContain("--model");
  expect(resumed.at(-1)).toBe("/d/snapshot.md");
});

test("readLink accepts only complete rex-btw markers", () => {
  expect(readLink({ type: "custom_message", customType: "rex-btw", details: thread } as any)).toEqual(thread);
  expect(
    readLink({ type: "custom_message", customType: "rex-btw", details: { ...thread, id: "x" } } as any),
  ).toBeUndefined();
  expect(readLink({ type: "custom_message", customType: "other", details: thread } as any)).toBeUndefined();
});

test("titleFor collapses whitespace and control characters", () => {
  expect(titleFor("  why\n\tthis?\u0007 ")).toBe("why this?");
  expect(titleFor("   ")).toBe("New BTW");
});
