import { expect, test } from "bun:test";
import { titleSequences, titles } from "./status.js";

test("working: spinner and name in the tab; the window adds the detail", () => {
  const name = "Explain nix-darwin dock autohide option";
  const t = titles({ phase: "working", detail: "bash ls", folder: "nix", name, frame: 1 });
  expect(t.tab).toBe("⠙ Explain nix-darwin dock…");
  expect(t.window).toBe(`⠙ ${name} · bash ls`);
});

test("unnamed sessions fall back to the folder", () => {
  expect(titles({ phase: "idle", detail: "", folder: "nix" })).toEqual({ tab: "nix", window: "nix" });
  expect(titles({ phase: "working", detail: "bash ls", folder: "nix" }).window).toBe("⠋ nix · bash ls");
});

test("OSC 2 carries the window title and OSC 1 the tab title", () => {
  const bytes = titleSequences({ phase: "done", detail: "ok", folder: "nix", name: "n" });
  expect(bytes).toBe("\x1b]2;✅ n · ok\x07\x1b]1;✅ n\x07\x1b]9;3;✅ n\x07");
});
