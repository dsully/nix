import { describe, it } from "node:test";
import { strict as assert } from "node:assert";
import { sortSkillsBySection } from "../types.ts";

describe("section ordering", () => {
  const skill = (name: string, group: string, enabled = true) => ({ name, group, enabled, path: `/${name}` }) as any;

  it("orders local, global, temporary, then disabled, each by name", () => {
    const sorted = sortSkillsBySection([
      skill("zeta", "global"),
      skill("off", "local", false),
      skill("rules", "temporary"),
      skill("beta", "local"),
      skill("alpha", "global"),
      skill("aoff", "global", false),
      skill("alpha-local", "local"),
    ]);
    assert.deepEqual(
      sorted.map((s) => s.name),
      ["alpha-local", "beta", "alpha", "zeta", "rules", "aoff", "off"],
    );
  });

  it("does not mutate the input", () => {
    const input = [skill("b", "local"), skill("a", "local")];
    sortSkillsBySection(input);
    assert.deepEqual(
      input.map((s) => s.name),
      ["b", "a"],
    );
  });
});
