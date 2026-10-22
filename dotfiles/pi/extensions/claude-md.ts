/**
 * Pi loads only the first of AGENTS.md / CLAUDE.md per directory; also load a sibling CLAUDE.md.
 */

import { existsSync, readFileSync, realpathSync } from "node:fs";
import { basename, dirname, join } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.on("before_agent_start", (event) => {
    const files = event.systemPromptOptions.contextFiles;
    const loaded = new Set(files.map((f) => realpathSync(f.path)));
    for (let i = files.length - 1; i >= 0; i--) {
      if (!/^AGENTS\.(md|MD)$/.test(basename(files[i].path))) continue;
      const path = ["CLAUDE.md", "CLAUDE.MD"].map((n) => join(dirname(files[i].path), n)).find((p) => existsSync(p));
      if (!path || loaded.has(realpathSync(path))) continue;
      files.splice(i + 1, 0, { path, content: readFileSync(path, "utf-8") });
    }
  });
}
