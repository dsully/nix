import { expect, test } from "bun:test";
import { keepsNative } from "./nested.js";

test("background tools keep their own rows", () => {
  expect(keepsNative({ toolName: "bg_run" })).toBe(true);
  expect(keepsNative({ toolName: "bg_status" })).toBe(true);
  expect(keepsNative({ toolName: "bg_kill" })).toBe(true);
});

test("markers owns collapsed tools and subagent plans", () => {
  expect(keepsNative({ getRenderShell: () => "self", toolName: "read" })).toBe(false);
  expect(keepsNative({ toolName: "subagent", args: { op: "run", prompt: "p" } })).toBe(false);
  expect(keepsNative({ toolName: "subagent", args: { op: "result", agent_id: "a" } })).toBe(false);
});
