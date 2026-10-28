import { existsSync, readFileSync, realpathSync } from "node:fs";
import { rm } from "node:fs/promises";
import { basename, dirname, isAbsolute, join, relative, resolve } from "node:path";
import {
  DefaultPackageManager,
  getAgentDir,
  parseFrontmatter,
  SettingsManager,
  type ExtensionContext,
  type PathMetadata,
  type SlashCommandInfo,
} from "@earendil-works/pi-coding-agent";
import { type SkillEntry, type SkillGroup, type SkillRegistry, type SkillScope, sortSkillsBySection } from "./types.js";

function projectRoot(cwd: string): string {
  for (let dir = cwd; dirname(dir) !== dir; dir = dirname(dir)) if (existsSync(join(dir, ".git"))) return dir;
  return cwd;
}

function isInside(path: string, root: string): boolean {
  const rel = relative(root, path);
  return !rel.startsWith("..") && !isAbsolute(rel);
}

// Symlinked copies of one skill (`.claude/skills` linked to `.agents/skills`) count once.
function canonicalPath(path: string): string {
  try {
    return realpathSync(path);
  } catch {
    return resolve(path);
  }
}

function parseSkillFile(path: string): Pick<SkillEntry, "name" | "description" | "frontmatter"> | null {
  try {
    const { frontmatter } = parseFrontmatter<Record<string, unknown>>(readFileSync(path, "utf8"));
    const name = typeof frontmatter.name === "string" ? frontmatter.name.trim() : "";
    const description = typeof frontmatter.description === "string" ? frontmatter.description.trim() : "";
    if (!name || !description) return null;
    return {
      name,
      description,
      frontmatter: Object.fromEntries(Object.entries(frontmatter).filter(([, value]) => value !== undefined)),
    };
  } catch {
    return null;
  }
}

function toSkillEntry(path: string, metadata: PathMetadata, enabled: boolean, root: string): SkillEntry | null {
  const parsed = parseSkillFile(path);
  if (!parsed) return null;
  const group: SkillGroup =
    metadata.scope === "user" ? "global" : metadata.scope === "project" || isInside(path, root) ? "local" : "temporary";
  return {
    ...parsed,
    path,
    scope: metadata.scope as SkillScope,
    group,
    origin: metadata.origin,
    source: metadata.source,
    baseDir: metadata.baseDir,
    enabled,
  };
}

/**
 * Settings-resolved skills, disabled ones included, plus the skills the
 * session loaded from elsewhere: extension `resources_discover` paths and CLI
 * flags, which only the session's resource loader sees (`pi.getCommands()`
 * lists its `getSkills()`).
 */
export async function loadSkillRegistry(
  cwd: string,
  projectTrusted: boolean,
  commands: SlashCommandInfo[],
): Promise<SkillRegistry> {
  const agentDir = getAgentDir();
  const settingsManager = SettingsManager.create(cwd, agentDir, { projectTrusted });
  const resolved = await new DefaultPackageManager({ cwd, agentDir, settingsManager }).resolve();
  const root = projectRoot(cwd);
  const seen = new Set<string>();
  const entries: SkillEntry[] = [];
  const add = (entry: SkillEntry | null) => {
    if (!entry || seen.has(canonicalPath(entry.path))) return;
    seen.add(canonicalPath(entry.path));
    entries.push(entry);
  };
  for (const resource of resolved.skills) add(toSkillEntry(resource.path, resource.metadata, resource.enabled, root));
  for (const command of commands)
    if (command.source === "skill") add(toSkillEntry(command.sourceInfo.path, command.sourceInfo, true, root));
  return { allSkills: sortSkillsBySection(entries) };
}

/** Only project skills are edited here; user-level skills and settings are managed outside pi. */
export function isTogglableSkill(skill: SkillEntry): boolean {
  return skill.scope === "project";
}

export function isDeletableSkill(skill: SkillEntry): boolean {
  return skill.origin === "top-level" && skill.scope === "project";
}

export function skillStorageTarget(skill: SkillEntry): string {
  return basename(skill.path).toLowerCase() === "skill.md" ? dirname(skill.path) : skill.path;
}

/**
 * Removes a skill's directory, or its file when it is not a SKILL.md, through
 * an awaited `rm`, so the dialog can show its deleting state and Pi keeps
 * rendering between filesystem batches. Resolves true once the removal
 * finished and was reported; a failed removal is reported and resolves false.
 */
export async function deleteSkill(ctx: ExtensionContext, skill: SkillEntry): Promise<boolean> {
  if (!isDeletableSkill(skill)) {
    ctx.ui.notify("Only project skills can be deleted", "warning");
    return false;
  }
  try {
    await rm(skillStorageTarget(skill), { recursive: true, force: true });
  } catch (error) {
    ctx.ui.notify(
      `Cannot delete skill ${skill.name}: ${error instanceof Error ? error.message : String(error)}`,
      "error",
    );
    return false;
  }
  ctx.ui.notify(`Deleted skill: ${skill.name}`, "info");
  return true;
}
