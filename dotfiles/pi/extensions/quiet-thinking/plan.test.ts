import { expect, test } from "bun:test";
import { dropHiddenThinking, type Part } from "./plan.js";

const spacer: Part = { kind: "spacer" };
const hidden: Part = { kind: "thinking", hidden: true };
const shown: Part = { kind: "thinking", hidden: false };
const text: Part = { kind: "text" };
const tools: Part = { kind: "toolCalls" };
const error: Part = { kind: "error" };

test("thinking-only tool round renders nothing", () => {
  expect(dropHiddenThinking([spacer, hidden, tools])).toEqual([tools]);
});

test("thinking before text keeps one leading spacer", () => {
  expect(dropHiddenThinking([spacer, hidden, spacer, text, tools])).toEqual([spacer, text, tools]);
});

test("thinking between texts keeps the separating spacer", () => {
  expect(dropHiddenThinking([spacer, text, hidden, spacer, text, tools])).toEqual([spacer, text, spacer, text, tools]);
});

test("errors keep their spacer", () => {
  expect(dropHiddenThinking([spacer, hidden, tools, spacer, error])).toEqual([tools, spacer, error]);
});

test("expanded thinking is untouched", () => {
  const parts = [spacer, shown, spacer, text, tools];
  expect(dropHiddenThinking(parts)).toEqual(parts);
});
