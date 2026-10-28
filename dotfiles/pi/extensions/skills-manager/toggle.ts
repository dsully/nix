import { dirname, join, relative } from "node:path";
import { getAgentDir, SettingsManager, type PackageSource } from "@earendil-works/pi-coding-agent";
import { isTogglableSkill } from "./registry.js";
import type { SkillEntry } from "./types.js";

function updatePatterns(current: string[], pattern: string, enabled: boolean): string[] {
  const updated = current.filter((entry) => {
    const stripped = entry.startsWith("!") || entry.startsWith("+") || entry.startsWith("-") ? entry.slice(1) : entry;
    return stripped !== pattern;
  });
  updated.push(`${enabled ? "+" : "-"}${pattern}`);
  return updated;
}

function hasPackageFilters(pkg: Exclude<PackageSource, string>): boolean {
  return (
    pkg.extensions !== undefined || pkg.skills !== undefined || pkg.prompts !== undefined || pkg.themes !== undefined
  );
}

/** Writes an enable/disable pattern for a project skill into the project's `.pi/settings.json`. */
export async function setSkillEnabled(
  cwd: string,
  skill: SkillEntry,
  enabled: boolean,
  projectTrusted: boolean,
): Promise<void> {
  if (!isTogglableSkill(skill)) throw new Error("Only project skills can be toggled here.");
  if (!projectTrusted) throw new Error("Project skills cannot be changed before project trust is active.");
  const settingsManager = SettingsManager.create(cwd, getAgentDir(), { projectTrusted });
  const settings = settingsManager.getProjectSettings();

  if (skill.origin === "top-level") {
    const pattern = relative(skill.baseDir ?? join(cwd, ".pi"), skill.path);
    settingsManager.setProjectSkillPaths(updatePatterns([...(settings.skills ?? [])], pattern, enabled));
    await settingsManager.flush();
    return;
  }

  const packages = [...(settings.packages ?? [])];
  const packageIndex = packages.findIndex((pkg) => (typeof pkg === "string" ? pkg : pkg.source) === skill.source);
  if (packageIndex === -1) throw new Error("Could not find the package settings entry for this skill.");
  const packageEntry = packages[packageIndex]!;
  const packageConfig = typeof packageEntry === "string" ? { source: packageEntry } : { ...packageEntry };
  const updated = updatePatterns(
    [...(packageConfig.skills ?? [])],
    relative(skill.baseDir ?? dirname(skill.path), skill.path),
    enabled,
  );
  packageConfig.skills = updated.length > 0 ? updated : undefined;
  packages[packageIndex] = hasPackageFilters(packageConfig) ? packageConfig : packageConfig.source;
  settingsManager.setProjectPackages(packages);
  await settingsManager.flush();
}
