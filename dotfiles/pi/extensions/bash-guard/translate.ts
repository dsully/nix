import { homedir } from "node:os";
import { resolve } from "node:path";
import { breToRegex } from "./bre.js";
import { extractFlatShellCommandSegments } from "./shell-tokenize.js";

export interface Translation {
  tool: "read" | "grep" | "find";
  args: Record<string, string | number | boolean>;
  /** For `tail -N`: the caller turns this into a read offset once it knows the file length. */
  tailLines?: number;
  /** `limit` came from a per-file max count, so it is exact only when `path` names a file. */
  fileOnly?: boolean;
  /** Run once per path (`args.path` unset); `args.limit` caps each run. */
  paths?: string[];
  /** Matches allowed across all `paths` runs together, from a piped `head`. */
  totalLimit?: number;
}

const UNQUOTED_SPECIAL = /[\\$`[\]{}()<>|;&~#!\n'"]/;
const UNQUOTED_GLOB = /[*?]/;

/** Splits a command made only of plain and simply quoted words; undefined for anything the shell would expand. */
export function shellWords(command: string): string[] | undefined {
  const words: string[] = [];
  const s = command.trim();
  let i = 0;
  while (i < s.length) {
    while (s[i] === " " || s[i] === "\t") i++;
    if (i >= s.length) break;
    const start = i;
    let word = "";
    while (i < s.length && s[i] !== " " && s[i] !== "\t") {
      const ch = s[i];
      if (ch === "'" || ch === '"') {
        const end = s.indexOf(ch, i + 1);
        if (end === -1) return undefined;
        const quoted = s.slice(i + 1, end);
        if (ch === '"' && /[\\$`]/.test(quoted)) return undefined;
        word += quoted;
        i = end + 1;
        continue;
      }
      if (UNQUOTED_SPECIAL.test(ch)) return undefined;
      // An unquoted glob in an option word (`--include=*.ts`) matches no file, so the shell leaves it as is.
      if (UNQUOTED_GLOB.test(ch) && s[start] !== "-") return undefined;
      word += ch;
      i++;
    }
    words.push(word);
  }
  return words;
}

const COUNT = /^\d+$/;

function positiveCount(value: string | undefined): number | undefined {
  if (value === undefined || !COUNT.test(value)) return undefined;
  const n = Number(value);
  return n > 0 ? n : undefined;
}

function lineArgs(args: string[]): { spec: string; files: string[] } | undefined {
  let spec: string | undefined = "10";
  const files: string[] = [];
  for (let i = 0; i < args.length; i++) {
    const word = args[i];
    if (word === "-n") spec = args[++i];
    else if (word.startsWith("--lines=")) spec = word.slice("--lines=".length);
    else if (/^-n.+/.test(word)) spec = word.slice(2);
    else if (/^-\d+$/.test(word)) spec = word.slice(1);
    else if (word.startsWith("-")) return undefined;
    else files.push(word);
  }
  return spec === undefined ? undefined : { spec, files };
}

function translateHeadTail(command: "head" | "tail", args: string[]): Translation | undefined {
  const parsed = lineArgs(args);
  if (parsed?.files.length !== 1) return undefined;
  const { spec } = parsed;
  const path = parsed.files[0];
  if (command === "tail" && spec.startsWith("+")) {
    const offset = positiveCount(spec.slice(1));
    return offset ? { tool: "read", args: { path, offset } } : undefined;
  }
  const count = positiveCount(spec);
  if (!count) return undefined;
  return command === "head"
    ? { tool: "read", args: { path, limit: count } }
    : { tool: "read", args: { path }, tailLines: count };
}

// rg's `-E` is --encoding, so `E` is accepted only for grep.
const SEARCH_SHORT_FLAGS = { rg: "iFn", grep: "iFnrRE" };

function translateSearch(command: "rg" | "grep", args: string[]): Translation | undefined {
  let ignoreCase = false;
  let literal = false;
  let extended = command === "rg";
  let recursive = command === "rg";
  let context: number | undefined;
  let maxCount: number | undefined;
  let glob: string | undefined;
  const positional: string[] = [];

  const setGlob = (value: string | undefined): boolean => {
    if (value === undefined || glob !== undefined || value.startsWith("!")) return false;
    glob = value;
    return true;
  };
  const setContext = (value: string | undefined): boolean => {
    context = positiveCount(value);
    return context !== undefined;
  };
  const setMaxCount = (value: string | undefined): boolean => {
    maxCount = positiveCount(value);
    return maxCount !== undefined;
  };

  for (let i = 0; i < args.length; i++) {
    const word = args[i];
    if (word === "--") {
      positional.push(...args.slice(i + 1));
      break;
    }
    if (!word.startsWith("-") || word === "-") {
      positional.push(word);
      continue;
    }
    if (word === "--ignore-case") ignoreCase = true;
    else if (word === "--fixed-strings") literal = true;
    else if (word === "--line-number") continue;
    else if (word === "--recursive" && command === "grep") recursive = true;
    else if (word === "--extended-regexp" && command === "grep") extended = true;
    else if (word === "-C" || word === "--context") {
      if (!setContext(args[++i])) return undefined;
    } else if (word.startsWith("--context=")) {
      if (!setContext(word.slice("--context=".length))) return undefined;
    } else if (/^-C\d+$/.test(word)) {
      if (!setContext(word.slice(2))) return undefined;
    } else if (word === "-m" || word === "--max-count") {
      if (!setMaxCount(args[++i])) return undefined;
    } else if (word.startsWith("--max-count=")) {
      if (!setMaxCount(word.slice("--max-count=".length))) return undefined;
    } else if (/^-m\d+$/.test(word)) {
      if (!setMaxCount(word.slice(2))) return undefined;
    } else if (command === "rg" && (word === "-g" || word === "--glob")) {
      if (!setGlob(args[++i])) return undefined;
    } else if (command === "rg" && word.startsWith("--glob=")) {
      if (!setGlob(word.slice("--glob=".length))) return undefined;
    } else if (command === "grep" && word.startsWith("--include=")) {
      if (!setGlob(word.slice("--include=".length))) return undefined;
    } else if (/^-[A-Za-z]+$/.test(word)) {
      for (const flag of word.slice(1)) {
        if (!SEARCH_SHORT_FLAGS[command].includes(flag)) return undefined;
        if (flag === "i") ignoreCase = true;
        else if (flag === "F") literal = true;
        else if (flag === "r" || flag === "R") recursive = true;
        else if (flag === "E") extended = true;
      }
    } else return undefined;
  }

  const [pattern, ...paths] = positional;
  if (pattern === undefined || paths.includes("-")) return undefined;
  // grep without a path reads stdin unless it searches recursively.
  if (command === "grep" && paths.length === 0 && !recursive) return undefined;
  const regex = extended || literal ? pattern : breToRegex(pattern);
  if (regex === undefined) return undefined;

  const result: Translation["args"] = { pattern: regex };
  if (paths.length === 1) result.path = paths[0];
  if (ignoreCase) result.ignoreCase = true;
  if (literal) result.literal = true;
  if (context !== undefined) result.context = context;
  if (glob !== undefined) result.glob = glob;
  const search: Translation = { tool: "grep", args: result };
  if (paths.length > 1) search.paths = paths;
  if (maxCount === undefined) return search;
  if (paths.length === 0) return undefined;
  result.limit = maxCount;
  return { ...search, fileOnly: true };
}

function translateFind(args: string[]): Translation | undefined {
  let path: string | undefined;
  let i = 0;
  if (args[0] !== undefined && !args[0].startsWith("-")) {
    path = args[0];
    i = 1;
  }
  let pattern: string | undefined;
  for (; i < args.length; i++) {
    const word = args[i];
    if (word === "-name" && pattern === undefined && args[i + 1] !== undefined) pattern = args[++i];
    else if (word === "-type" && args[i + 1] === "f") i++;
    else return undefined;
  }
  if (pattern === undefined) return undefined;
  return { tool: "find", args: path === undefined ? { pattern } : { pattern, path } };
}

function translateFd(args: string[]): Translation | undefined {
  let glob = false;
  let extension: string | undefined;
  const positional: string[] = [];
  for (let i = 0; i < args.length; i++) {
    const word = args[i];
    if (word === "-g" || word === "--glob") glob = true;
    else if (word === "-e" || word === "--extension") {
      if (extension !== undefined || args[i + 1] === undefined) return undefined;
      extension = args[++i];
    } else if (word.startsWith("--extension=")) {
      if (extension !== undefined) return undefined;
      extension = word.slice("--extension=".length);
    } else if (word === "-t" || word === "--type") {
      if (args[++i] !== "f") return undefined;
    } else if (word === "--type=f") continue;
    else if (word.startsWith("-")) return undefined;
    else positional.push(word);
  }
  let pattern: string | undefined;
  let path: string | undefined;
  if (glob && extension === undefined && positional.length >= 1 && positional.length <= 2) {
    [pattern, path] = positional;
  } else if (!glob && extension && positional.length <= 1) {
    pattern = `*.${extension.replace(/^\./, "")}`;
    [path] = positional;
  } else return undefined;
  return { tool: "find", args: path === undefined ? { pattern } : { pattern, path } };
}

function translateSimple(command: string): Translation | undefined {
  const words = shellWords(command);
  if (!words || words.length === 0) return undefined;
  const [name, ...args] = words;
  switch (name) {
    case "cat":
      return args.length === 1 && !args[0].startsWith("-") ? { tool: "read", args: { path: args[0] } } : undefined;
    case "head":
    case "tail":
      return translateHeadTail(name, args);
    case "rg":
    case "grep":
      return translateSearch(name, args);
    case "find":
      return translateFind(args);
    case "fd":
      return translateFd(args);
    default:
      return undefined;
  }
}

function headCount(stage: string): number | undefined {
  const words = shellWords(stage);
  if (words?.[0] !== "head") return undefined;
  const parsed = lineArgs(words.slice(1));
  return parsed?.files.length === 0 ? positiveCount(parsed.spec) : undefined;
}

function withLimit(translation: Translation, count: number): Translation | undefined {
  // `head` counts grep context lines; the grep tool's `limit` counts only matching lines.
  if (translation.args.context !== undefined) return undefined;
  const { limit } = translation.args;
  const args = { ...translation.args, limit: typeof limit === "number" ? Math.min(limit, count) : count };
  return translation.paths ? { ...translation, args, totalLimit: count } : { ...translation, args };
}

function translateLookup(command: string): Translation | undefined {
  const stages = extractFlatShellCommandSegments(command);
  if (stages.length !== 2) return translateSimple(command);
  const [source, head] = stages;
  const pipe = command.slice(command.indexOf(source.text) + source.text.length, command.lastIndexOf(head.text));
  if (!head.pipedStdin || pipe.trim() !== "|") return undefined;
  const translation = translateSimple(source.text);
  const count = headCount(head.text);
  return translation && count ? withLimit(translation, count) : undefined;
}

const CD_HOME = /^cd\s+~(\/[\w./-]*)?$/;

function cdTarget(segment: string): string | undefined {
  const home = CD_HOME.exec(segment);
  if (home) return homedir() + (home[1] ?? "");
  const words = shellWords(segment);
  return words?.length === 2 && words[0] === "cd" ? words[1] : undefined;
}
/** Returns the command after a leading `cd <cwd> &&` or `cd <cwd>;`, which changes nothing. */
function withoutCdToCwd(command: string, cwd: string): string | undefined {
  const [first, second] = extractFlatShellCommandSegments(command);
  const dir = first && cdTarget(first.text);
  if (!second || dir === undefined || resolve(cwd, dir) !== resolve(cwd)) return undefined;
  const firstEnd = command.indexOf(first.text) + first.text.length;
  const rest = command.indexOf(second.text, firstEnd);
  const separator = command.slice(firstEnd, rest).trim();
  return separator === "&&" || separator === ";" ? command.slice(rest) : undefined;
}

/**
 * Maps a simple cat/head/tail/rg/grep/find/fd command, optionally piped into `head`, to the equivalent native tool call.
 * With `cwd`, a leading `cd` into it is dropped first.
 */
export function translate(command: string, cwd?: string): Translation | undefined {
  const lookup = cwd === undefined ? undefined : withoutCdToCwd(command, cwd);
  return translateLookup(lookup ?? command);
}
