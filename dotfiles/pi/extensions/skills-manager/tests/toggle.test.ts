import { afterAll, beforeAll, expect, test } from "bun:test";
import { mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

import { loadSkillRegistry } from "../registry.ts";
import { setSkillEnabled } from "../toggle.ts";

let root = "";
let cwd = "";
const previousAgentDir = process.env.PI_CODING_AGENT_DIR;

beforeAll(() => {
  root = mkdtempSync(join(tmpdir(), "pi-skills-manager-toggle-"));
  cwd = join(root, "project");
  for (const [dir, name] of [
    [join(cwd, ".pi", "skills", "local"), "local"],
    [join(root, "agent", "skills", "shared"), "shared"],
  ] as const) {
    mkdirSync(dir, { recursive: true });
    writeFileSync(join(dir, "SKILL.md"), `---\nname: ${name}\ndescription: The ${name} skill.\n---\n`);
  }
  process.env.PI_CODING_AGENT_DIR = join(root, "agent");
});

afterAll(() => {
  rmSync(root, { recursive: true, force: true });
  if (previousAgentDir === undefined) delete process.env.PI_CODING_AGENT_DIR;
  else process.env.PI_CODING_AGENT_DIR = previousAgentDir;
});

const skillNamed = async (name: string) =>
  (await loadSkillRegistry(cwd, true, [])).allSkills.find((skill) => skill.name === name)!;

test("disabling a project skill writes a project pattern that pi then resolves as disabled", async () => {
  await setSkillEnabled(cwd, await skillNamed("local"), false, true);
  expect(JSON.parse(readFileSync(join(cwd, ".pi", "settings.json"), "utf8")).skills).toEqual([
    "-skills/local/SKILL.md",
  ]);
  expect((await skillNamed("local")).enabled).toBe(false);
});

test("user-level skills and untrusted projects are refused", async () => {
  await expect(setSkillEnabled(cwd, await skillNamed("shared"), false, true)).rejects.toThrow("Only project skills");
  await expect(setSkillEnabled(cwd, await skillNamed("local"), true, false)).rejects.toThrow("project trust");
});
