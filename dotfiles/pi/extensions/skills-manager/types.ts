export type OverlaySize = number | `${number}%` | string;
export type SkillScope = "user" | "project" | "temporary";
/** Where the manager lists a skill: in the project tree, user-wide, or loaded for this session from elsewhere. */
export type SkillGroup = "local" | "global" | "temporary";
export type SkillSection = SkillGroup | "disabled";
export type SkillOrigin = "package" | "top-level";
export type Mode = "browse" | "preview" | "delete-confirm" | "deleting";

/** One skill in the inventory. The body is not held here: the preview reads
 *  it from `path` for the one skill it shows. */
export interface SkillEntry {
  name: string;
  description: string;
  path: string;
  frontmatter?: Record<string, unknown>;
  scope: SkillScope;
  group: SkillGroup;
  origin: SkillOrigin;
  source: string;
  baseDir?: string;
  enabled: boolean;
}

export interface SkillRegistry {
  allSkills: SkillEntry[];
}

const SKILL_SECTIONS: readonly SkillSection[] = ["local", "global", "temporary", "disabled"];

export function skillSection(skill: SkillEntry): SkillSection {
  return skill.enabled ? skill.group : "disabled";
}

export function sortSkillsBySection(skills: SkillEntry[]): SkillEntry[] {
  const rank = (skill: SkillEntry) => SKILL_SECTIONS.indexOf(skillSection(skill));
  return [...skills].sort((a, b) => rank(a) - rank(b) || a.name.localeCompare(b.name) || a.path.localeCompare(b.path));
}

export interface SkillsManagerOptions {
  onDelete: (skill: SkillEntry) => Promise<boolean>;
  onToggle: (skill: SkillEntry, enabled: boolean) => Promise<void>;
  onRefresh: () => Promise<SkillRegistry>;
}
