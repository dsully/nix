/**
 * Pi skills manager: /skill browses, previews and inserts skills, and
 * enables, disables or deletes project skills. Also loads Claude Code
 * project skills (`.claude/skills` within the current git repo).
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { claudeSkillDirs } from "./claude-skills.js";

function errorMessage(error: unknown): string {
  const message = error instanceof Error ? error.message : String(error);
  return message.length > 180 ? `${message.slice(0, 179)}…` : message;
}

export default function skillsManager(pi: ExtensionAPI): void {
  pi.on("resources_discover", (event) => ({ skillPaths: claudeSkillDirs(event.cwd) }));

  pi.registerCommand("skill", {
    description: "Pi skills manager view. Native skills remain /skill:name.",
    handler: async (args, ctx) => {
      if (args.trim()) {
        ctx.ui.notify(
          "Use /skill:name for native skill invocation, or /skill with no arguments for the manager.",
          "warning",
        );
        return;
      }
      if (!ctx.hasUI) {
        ctx.ui.notify("/skill manager requires interactive mode", "warning");
        return;
      }
      // Loaded on first use so sessions that never open the manager pay nothing.
      let modules;
      try {
        modules = await Promise.all([import("./dialog.js"), import("./registry.js"), import("./toggle.js")]);
      } catch (error) {
        ctx.ui.notify(`Failed to load skills manager: ${errorMessage(error)}`, "error");
        return;
      }
      const [{ showSkillsManager }, { deleteSkill, loadSkillRegistry }, { setSkillEnabled }] = modules;
      const trusted = ctx.isProjectTrusted();
      const load = () => loadSkillRegistry(ctx.cwd, trusted, pi.getCommands());
      let registry;
      try {
        registry = await load();
      } catch (error) {
        ctx.ui.notify(`Failed to load skills list: ${errorMessage(error)}`, "error");
        return;
      }
      const selection = await showSkillsManager(ctx, registry, {
        onDelete: async (skill) => await deleteSkill(ctx, skill),
        onToggle: async (skill, enabled) => await setSkillEnabled(ctx.cwd, skill, enabled, trusted),
        onRefresh: load,
      });
      if (selection) ctx.ui.pasteToEditor(`/skill:${selection.name}\n`);
    },
  });
}
