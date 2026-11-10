import { expect, test } from "bun:test";
import { collapseThinking, silentParts, thinkingLive, thoughtLabel } from "./label.js";

test("thinking is live only while it is the last streamed block", () => {
  expect(thinkingLive([{ type: "thinking" }], true)).toBe(true);
  expect(thinkingLive([{ type: "thinking" }, { type: "text" }], true)).toBe(false);
  expect(thinkingLive([{ type: "thinking" }], false)).toBe(false);
});

test("a settled thought shows its first line and how long it took", () => {
  const label = thoughtLabel("check the API", false, 2500);
  expect(label).toContain("check the API");
  expect(label).toContain("2.5s");
  expect(thoughtLabel(undefined, false, undefined)).not.toContain(":");
});

test("a live thought spins", () => {
  expect(thoughtLabel("x", true, 0)).not.toBe(thoughtLabel("x", true, 80));
});

test("only the last hidden thinking part stays", () => {
  const parts = [
    { kind: "thinking", hidden: true },
    { kind: "spacer" },
    { kind: "thinking", hidden: true },
    { kind: "text" },
  ];
  expect(collapseThinking(parts).filter((p) => p.kind === "thinking")).toHaveLength(1);
});

test("silent mode hides messages that call tools and the thinking of answers", () => {
  const calling = [{ kind: "spacer" }, { kind: "text" }, { kind: "toolCalls", present: true }];
  expect(silentParts(calling).map((p) => p.kind)).toEqual(["toolCalls"]);
  const answer = [
    { kind: "spacer" },
    { kind: "thinking" },
    { kind: "spacer" },
    { kind: "text" },
    { kind: "toolCalls", present: false },
  ];
  expect(silentParts(answer).some((p) => p.kind === "thinking")).toBe(false);
  expect(silentParts(answer).some((p) => p.kind === "text")).toBe(true);
});
