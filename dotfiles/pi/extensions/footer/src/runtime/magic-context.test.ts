import { expect, test } from "bun:test";
import { parseMagicContextStatus } from "./magic-context.js";

test("parses the idle status the extension publishes", () => {
  expect(parseMagicContextStatus("mc: 92.4K (10%) · idle")).toEqual({ tokens: 92_400, percent: 10 });
});

test("parses millions, thousands and bare counts", () => {
  expect(parseMagicContextStatus("mc: 1.2M (71%) · historian")).toEqual({ tokens: 1_200_000, percent: 71 });
  expect(parseMagicContextStatus("mc: 640 (43%) · recomp")).toEqual({ tokens: 640, percent: 43 });
});

test("accepts the failure and compaction states", () => {
  expect(parseMagicContextStatus("mc: 512.5K (55%) · ⚠ historian failed")).toEqual({ tokens: 512_500, percent: 55 });
});

test("has no reading before the first usage or at a rounded-away percentage", () => {
  expect(parseMagicContextStatus("mc: -- (--) · idle")).toBeUndefined();
  expect(parseMagicContextStatus("mc: 900 (0%) · idle")).toBeUndefined();
});

test("ignores other extensions' status lines", () => {
  expect(parseMagicContextStatus(undefined)).toBeUndefined();
  expect(parseMagicContextStatus("gortex: indexing")).toBeUndefined();
});
