import { expect, test } from "bun:test";
import { usesPiFallback } from "./subagent.js";

test("result and steer ops use pi's fallback", () => {
  expect(usesPiFallback("subagent", { op: "result", agent_id: "a" })).toBe(true);
  expect(usesPiFallback("subagent", { op: "steer", agent_id: "a", message: "m" })).toBe(true);
});

test("ops with an upstream renderer keep it", () => {
  for (const op of ["run", "workflow", "help"]) expect(usesPiFallback("subagent", { op })).toBe(false);
});

test("op inferred from agent_id alone", () => {
  expect(usesPiFallback("subagent", { agent_id: "a" })).toBe(true);
  expect(usesPiFallback("subagent", { agent_id: "a", prompt: "p" })).toBe(false);
});

test("other tools are untouched", () => {
  expect(usesPiFallback("bash", { op: "result" })).toBe(false);
  expect(usesPiFallback("subagent", undefined)).toBe(false);
});
