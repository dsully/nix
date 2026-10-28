import { expect, test } from "bun:test";

import { openManager, projectSkill, registryOf, scratchProject } from "./harness.ts";

const project = scratchProject("pi-skills-manager-sections-");

test("the browse list draws one divider per section in place of a per-row scope tag", async () => {
  const local = projectSkill(project.cwd, "mine");
  const global = { ...projectSkill(project.cwd, "shared"), scope: "user" as const, group: "global" as const };
  const off = { ...projectSkill(project.cwd, "off"), enabled: false };
  const manager = openManager(project.cwd, registryOf([off, global, local]));
  const frame = manager.component.render(100);
  const list = frame.slice(
    frame.findIndex((line) => line.includes("── Local")),
    frame.findIndex((line) => line.includes("off")) + 1,
  );
  const lines = list.map((line) => line.replace(/^[│┃ ]+/, "").replace(/ — .*| ─{3,}.*/, ""));
  manager.close();
  await manager.shown;

  expect(lines).toEqual(["── Local", "(✓) mine", "", "── Global", "(✓) shared", "", "── Disabled", "(✗) off"]);
});
