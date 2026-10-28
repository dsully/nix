import { readFileSync } from "node:fs";
import { stripFrontmatter } from "@earendil-works/pi-coding-agent";
import type { SkillEntry } from "./types.js";

function formatScalar(value: unknown): string {
  if (typeof value === "string") {
    if (value.length === 0) return '""';
    if (/^[A-Za-z0-9_./@,+()[\]\- ]+$/.test(value) && !value.includes(": ") && !/^\s|\s$/.test(value)) return value;
    return JSON.stringify(value);
  }
  if (typeof value === "number" || typeof value === "boolean") return String(value);
  if (value === null) return "null";
  return JSON.stringify(value);
}

export function formatYamlValue(key: string, value: unknown, indent = ""): string[] {
  if (typeof value === "string" && value.includes("\n")) {
    return [`${indent}${key}: |`, ...value.split("\n").map((line) => `${indent}  ${line}`)];
  }
  if (Array.isArray(value)) {
    if (value.length === 0) return [`${indent}${key}: []`];
    return [
      `${indent}${key}:`,
      ...value.flatMap((item) => {
        if (item && typeof item === "object") {
          return [
            `${indent}  -`,
            ...Object.entries(item as Record<string, unknown>).flatMap(([nestedKey, nestedValue]) =>
              formatYamlValue(nestedKey, nestedValue, `${indent}    `),
            ),
          ];
        }
        return [`${indent}  - ${formatScalar(item)}`];
      }),
    ];
  }
  if (value && typeof value === "object") {
    const entries = Object.entries(value as Record<string, unknown>);
    if (entries.length === 0) return [`${indent}${key}: {}`];
    return [
      `${indent}${key}:`,
      ...entries.flatMap(([nestedKey, nestedValue]) => formatYamlValue(nestedKey, nestedValue, `${indent}  `)),
    ];
  }
  return [`${indent}${key}: ${formatScalar(value)}`];
}

export function buildFrontmatterBlock(skill: SkillEntry): string {
  const frontmatter = skill.frontmatter ?? { name: skill.name, description: skill.description };
  const lines = Object.entries(frontmatter).flatMap(([key, value]) => formatYamlValue(key, value));
  return ["---", ...lines, "---"].join("\n");
}

/** The body of one skill as the preview shows it, or why its file cannot be read. */
export type SkillBody = { kind: "body"; text: string } | { kind: "unreadable"; reason: string };

export function readSkillBody(skill: SkillEntry): SkillBody {
  try {
    return { kind: "body", text: stripFrontmatter(readFileSync(skill.path, "utf8")).trim() };
  } catch (error) {
    return { kind: "unreadable", reason: error instanceof Error ? error.message : String(error) };
  }
}
