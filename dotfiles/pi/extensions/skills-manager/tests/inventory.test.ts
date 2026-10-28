import { afterAll, beforeAll, expect, test } from "bun:test";
import { mkdirSync, mkdtempSync, rmSync, symlinkSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

import { readSkillBody } from "../format.ts";
import { loadSkillRegistry } from "../registry.ts";

let root = "";
let cwd = "";
let extensionSkill = "";
let rulesSkill = "";
const previousAgentDir = process.env.PI_CODING_AGENT_DIR;

function writeSkill(dir: string, name: string): string {
  mkdirSync(dir, { recursive: true });
  const path = join(dir, "SKILL.md");
  writeFileSync(path, `---\nname: ${name}\ndescription: The ${name} skill.\n---\n\nThe ${name} body.\n`);
  return path;
}

beforeAll(() => {
  root = mkdtempSync(join(tmpdir(), "pi-skills-manager-inventory-"));
  cwd = join(root, "project");
  writeSkill(join(cwd, ".pi", "skills", "sample"), "sample");
  extensionSkill = writeSkill(join(cwd, ".claude", "skills", "claude"), "claude");
  rulesSkill = writeSkill(join(root, "rules-skills", "rules"), "rules");
  symlinkSync(join(cwd, ".pi", "skills", "sample"), join(cwd, ".claude", "skills", "sample"));
  mkdirSync(join(root, "agent"));
  process.env.PI_CODING_AGENT_DIR = join(root, "agent");
});

afterAll(() => {
  rmSync(root, { recursive: true, force: true });
  if (previousAgentDir === undefined) delete process.env.PI_CODING_AGENT_DIR;
  else process.env.PI_CODING_AGENT_DIR = previousAgentDir;
});

test("the inventory holds no skill body; the body is read for the skill shown", async () => {
  const registry = await loadSkillRegistry(cwd, true, []);
  const sample = registry.allSkills.find((skill) => skill.name === "sample");
  expect(sample).toMatchObject({ scope: "project", origin: "top-level", enabled: true });
  expect("content" in sample!).toBe(false);
  expect(readSkillBody(sample!)).toEqual({ kind: "body", text: "The sample body." });
});

test("session-loaded skills are grouped local inside the project and temporary outside it, and a symlinked copy counts once", async () => {
  const sourceInfo = {
    path: extensionSkill,
    source: "extension:skills-manager",
    scope: "temporary",
    origin: "top-level",
  } as const;
  const commands = [
    { name: "skill:rules", source: "skill", sourceInfo: { ...sourceInfo, path: rulesSkill } },
    {
      name: "skill:sample",
      source: "skill",
      sourceInfo: { ...sourceInfo, path: join(cwd, ".claude", "skills", "sample", "SKILL.md") },
    },
    { name: "skill:claude", source: "skill", sourceInfo },
    { name: "review", source: "prompt", sourceInfo: { ...sourceInfo, path: join(root, "review.md") } },
  ] as any;
  const registry = await loadSkillRegistry(cwd, true, commands);
  expect(registry.allSkills.map((skill) => [skill.name, skill.scope, skill.group])).toEqual([
    ["claude", "temporary", "local"],
    ["sample", "project", "local"],
    ["rules", "temporary", "temporary"],
  ]);
});
