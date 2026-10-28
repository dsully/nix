import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { searchesTooBroadly } from "./match.js";

const REASON = [
  "Searching from / (find, fd) or all of /nix/store (find, fd, rg, grep) is not allowed.",
  "For Nix files or derivations: `nix-locate <path>` finds the package that provides a file,",
  "`nix search nixpkgs <name>` finds packages, `nix eval --raw <flake>#<pkg>.outPath` or `nix path-info <installable>`",
  "gives a store path, and `nix-store -qR <path>` lists its closure; search inside that path, never all of /nix/store.",
  "Otherwise use `locate <name>` for system-wide lookups, or `fd <pattern> <dir>` scoped to a specific directory such as the repo or ~.",
].join(" ");

export default function (pi: ExtensionAPI) {
  pi.on("tool_call", async (event) => {
    const command = (event.input as { command?: unknown }).command;
    if (typeof command === "string" && searchesTooBroadly(command)) return { block: true, reason: REASON };
  });
}
