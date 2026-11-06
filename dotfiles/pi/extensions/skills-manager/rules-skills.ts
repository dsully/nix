import { readdirSync } from "node:fs";

// Skill name -> it is offered only when the git root matches.
const MARKERS: Record<string, (files: string[]) => boolean> = {
  "python-rules": (files) => files.includes("pyproject.toml") || files.some((f) => f.endsWith(".py")),
  "rust-rules": (files) => files.includes("Cargo.toml"),
};

export function rulesSkillsFor(root: string): string[] {
  let files: string[];
  try {
    files = readdirSync(root);
  } catch {
    files = [];
  }
  return Object.keys(MARKERS).filter((name) => MARKERS[name]!(files));
}
