import { readFileSync } from "node:fs";
import { homedir } from "node:os";
import { extname, join } from "node:path";

type Colors = Record<string, string>;
export type LlaTheme = {
  colors?: Colors;
  extensions?: { colors?: Colors; groups?: Record<string, string[]> };
  special_files?: { dotfiles?: Colors; exact_match?: Colors; patterns?: Colors; folders?: Colors };
};
export type EntryKind = "dir" | "file" | "symlink" | "exec";
export type EntryStyle = { color?: string; bold?: true; italic?: true; underline?: true };

const SECTION = /^\[([^\]]+)\]$/;
const PAIR = /^("[^"]*"|[\w-]+)\s*=\s*(.+)$/;

/** The TOML that pkgs.formats.toml writes for lla themes: tables, bare or quoted keys, strings and string arrays. */
export function parseToml(text: string): Record<string, unknown> {
  const root: Record<string, unknown> = {};
  let table = root;
  for (const raw of text.split("\n")) {
    const line = raw.trim();
    const section = SECTION.exec(line);
    if (section) {
      table = root;
      for (const key of section[1]!.split(".")) table = (table[key] ??= {}) as Record<string, unknown>;
      continue;
    }
    const pair = PAIR.exec(line);
    if (!pair) continue;
    try {
      table[pair[1]!.startsWith('"') ? JSON.parse(pair[1]!) : pair[1]!] = JSON.parse(pair[2]!);
    } catch {}
  }
  return root;
}

let cached: LlaTheme | null | undefined;

/** The theme lla's config names, from ~/.config/lla (lla ignores XDG_CONFIG_HOME); null when there is none. */
export function llaTheme(): LlaTheme | null {
  if (cached !== undefined) return cached;
  try {
    const dir = join(homedir(), ".config", "lla");
    const name = parseToml(readFileSync(join(dir, "config.toml"), "utf8")).theme;
    cached =
      typeof name === "string"
        ? (parseToml(readFileSync(join(dir, "themes", `${name}.toml`), "utf8")) as LlaTheme)
        : null;
  } catch {
    cached = null;
  }
  return cached;
}

function patternMatches(pattern: string, name: string): boolean {
  if (pattern.startsWith("*")) return name.endsWith(pattern.slice(1));
  if (pattern.endsWith("*")) return name.startsWith(pattern.slice(0, -1));
  return name === pattern;
}

function byPattern(colors: Colors | undefined, name: string): string | undefined {
  return colors?.[name] ?? Object.entries(colors ?? {}).find(([pattern]) => patternMatches(pattern, name))?.[1];
}

// lla's theme/mod.rs get_file_color, in its order; groups are tried in file order where lla's HashMap order is random.
function fileColor(theme: LlaTheme, name: string): string | undefined {
  const special = theme.special_files;
  const exact = special?.exact_match?.[name] ?? (name.startsWith(".") ? special?.dotfiles?.[name] : undefined);
  if (exact) return exact;
  const pattern = Object.entries(special?.patterns ?? {}).find(([p]) => patternMatches(p, name))?.[1];
  if (pattern) return pattern;
  const ext = extname(name).slice(1).toLowerCase();
  if (!ext) return theme.colors?.file;
  const colors = theme.extensions?.colors;
  const group = Object.entries(theme.extensions?.groups ?? {}).find(
    ([group, exts]) => colors?.[group] && exts.some((e) => e.toLowerCase() === ext),
  )?.[0];
  return colors?.[ext] ?? (group ? colors?.[group] : undefined) ?? theme.colors?.file;
}

/** How `lla` paints an entry's name; utils/color.rs colorize_file_name. */
export function entryStyle(theme: LlaTheme, name: string, kind: EntryKind): EntryStyle {
  switch (kind) {
    case "dir":
      return { color: byPattern(theme.special_files?.folders, name) ?? theme.colors?.directory, bold: true };
    case "symlink":
      return { color: theme.colors?.symlink, italic: true, underline: true };
    case "exec":
      return { color: theme.colors?.executable, bold: true };
    case "file":
      return { color: fileColor(theme, name) };
  }
}
