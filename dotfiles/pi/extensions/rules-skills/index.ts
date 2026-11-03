import { join } from "node:path";
import { getAgentDir, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { gitRoot } from "../lib/git-root.js";
import { rulesSkillsFor } from "./match.js";

/** Registers the language rules skills (linked by pi.nix into <agent dir>/rules-skills) only in repos written in that language. */
export default function (pi: ExtensionAPI) {
  pi.on("resources_discover", (event) => ({
    skillPaths: rulesSkillsFor(gitRoot(event.cwd) ?? event.cwd).map((name) =>
      join(getAgentDir(), "rules-skills", name),
    ),
  }));
}
