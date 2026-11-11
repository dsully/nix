import { expect, test } from "bun:test";
import { entryStyle, parseToml, type LlaTheme } from "./lla.js";

const theme: LlaTheme = parseToml(`
name = "t"

[colors]
directory = "#000001"
file = "#000002"
symlink = "#000003"
executable = "#000004"

[extensions.colors]
toml = "#000010"
data = "#000011"
rust = "#000012"

[extensions.groups]
data = ["csv", "yml"]
rust = ["rs", "toml"]

[special_files.exact_match]
"Cargo.toml" = "#000020"

[special_files.dotfiles]
".env" = "#000021"

[special_files.patterns]
"*.lock" = "#000022"

[special_files.folders]
".git" = "#000030"
"*-cache" = "#000031"
`) as LlaTheme;

test("toml subset: sections, quoted keys, string arrays", () => {
  expect(theme.special_files?.exact_match?.["Cargo.toml"]).toBe("#000020");
  expect(theme.extensions?.groups?.data).toEqual(["csv", "yml"]);
});

test("directories take folder colors, by name or pattern, then the directory color, in bold", () => {
  expect(entryStyle(theme, ".git", "dir")).toEqual({ color: "#000030", bold: true });
  expect(entryStyle(theme, "pip-cache", "dir").color).toBe("#000031");
  expect(entryStyle(theme, "src", "dir").color).toBe("#000001");
});

test("special files win over extensions; extensions win over groups", () => {
  expect(entryStyle(theme, "Cargo.toml", "file").color).toBe("#000020");
  expect(entryStyle(theme, ".env", "file").color).toBe("#000021");
  expect(entryStyle(theme, "uv.lock", "file").color).toBe("#000022");
  expect(entryStyle(theme, "x.toml", "file").color).toBe("#000010");
  expect(entryStyle(theme, "main.RS", "file").color).toBe("#000012");
  expect(entryStyle(theme, "notes", "file").color).toBe("#000002");
});

test("symlinks and executables keep lla's own colors and styles", () => {
  expect(entryStyle(theme, "x.toml", "symlink")).toEqual({ color: "#000003", italic: true, underline: true });
  expect(entryStyle(theme, "run", "exec")).toEqual({ color: "#000004", bold: true });
});
