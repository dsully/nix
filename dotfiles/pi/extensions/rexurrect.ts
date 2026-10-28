import { spawn } from "node:child_process";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

// rexurrect restores a Rex block running pi with `pi --session <id>`; see [programs.pi] in modules/dev/rex/rex.nix.
export default function (pi: ExtensionAPI) {
  if (!process.env.REX_BLOCK) return;
  pi.on("session_start", (_event, ctx) => {
    const id = ctx.sessionManager.getSessionId();
    if (!id) return;
    spawn("rexurrect", ["report", "pi", id], { stdio: "ignore", detached: true })
      .on("error", () => {})
      .unref();
  });
}
