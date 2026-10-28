import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { claudeSkillDirs } from "./paths.js";

/** Load Claude Code project skills (`.claude/skills` within the current git repo). */
export default function (pi: ExtensionAPI) {
  pi.on("resources_discover", (event) => ({ skillPaths: claudeSkillDirs(event.cwd) }));
}
