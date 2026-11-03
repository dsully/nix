// From oh-my-pi packages/coding-agent/src/tools/bash-interceptor.ts and exec/settings.ts (MIT, see LICENSE),
// with each rule's tool and message mapped to this harness's tools.
import { extractFlatShellCommandSegments } from "./shell-tokenize.js";

interface Rule {
  pattern: string;
  tool: string;
  message: string;
}

export const RULES: Rule[] = [
  {
    // `cat` that sends stdout to a file or reads a heredoc writes rather than
    // reads, also after leading redirects of other fds (`cat 2>err > out`);
    // the write rule below owns those forms. `cat 2>err file` and
    // `cat >&2 file` (stdout duplicated, not sent to a file) still read.
    // A redirect target cannot start with `>` or `|`, so each leading
    // redirect is consumed one way and matching stays linear.
    pattern:
      "^\\s*(?:(?:head|tail|less|more)\\s+|cat\\s+(?!\\s|(?:[02-9]>{1,2}\\|?\\s*[^\\s>|]\\S*\\s+)*(?:<<|1?>(?!&)|&>)))",
    tool: "read",
    message: "Use the `read` tool instead of cat/head/tail; page with offset/limit.",
  },
  {
    pattern: "^\\s*(grep|rg|ripgrep|ag|ack)\\s+",
    tool: "grep",
    message: "Use the `grep` tool instead of grep/rg. It respects .gitignore and returns editable anchors.",
  },
  {
    pattern: "^\\s*(find|fd|locate)\\s+.*(-name|-iname|-type|--type|-glob)",
    tool: "find",
    message: "Use the `find` tool (or `fffind`) instead of find/fd. It respects .gitignore.",
  },
  {
    pattern: "^\\s*sed\\s+(-i|--in-place)",
    tool: "replace",
    message: "Use `read` then `replace`/`insert` instead of sed -i.",
  },
  {
    pattern: "^\\s*perl\\s+.*-[pn]?i",
    tool: "replace",
    message: "Use `read` then `replace`/`insert` instead of perl -i.",
  },
  {
    pattern: "^\\s*awk\\s+.*-i\\s+inplace",
    tool: "replace",
    message: "Use `read` then `replace`/`insert` instead of awk -i inplace.",
  },
  {
    // `>` must sit outside quoted regions (so `echo "a -> b"` passes) and be
    // followed by a plausible filename — including `$VAR` targets; `>|`
    // (clobber) counts as a redirect; `>&2`/`2>&1` style fd duplication and
    // redirects of fds other than stdout (`2>err.log`) are not matched, and
    // the scan continues past them and past input duplication (`<&0`), so
    // `2>&1 > out.txt` is a write. The scan stops at an unquoted,
    // unescaped `;`, `&&`, `|` or newline outside a command substitution,
    // so a redirect in a later command or a heredoc body is not attributed
    // to the echo/cat, while `echo foo\; > out.txt` and
    // `echo $(printf a; printf b) > out.txt` keep theirs. Allowed device
    // sinks are consumed while looking for later real file redirects
    // because the write tool cannot replace shell output/discard targets.
    // Each character has exactly one way to be consumed (an fd-numbered
    // redirect only by the fd branch, an escape only by the escape branch,
    // a `$(`, `${` or backtick only by the substitution branch, and as a
    // plain character only when that branch cannot consume it, so a deeper
    // nesting such as `${a:-${b}}` is scanned as before), which keeps
    // matching linear on long commands.
    pattern:
      "^\\s*(?:(?:echo|printf)\\s+|cat\\s*<<|cat(?=\\s+(?:\\d+|&)?>)\\s+)(?:(?:\\\\[\\s\\S]|\\$\\((?:[^()\"'`]|\"[^\"]*\"|'[^']*'|`[^`]*`|\\([^()]*\\))*\\)|\\$\\{[^{}]*\\}|`[^`]*`|\\$(?!\\((?:[^()\"'`]|\"[^\"]*\"|'[^']*'|`[^`]*`|\\([^()]*\\))*\\)|\\{[^{}]*\\})|`(?![^`]*`)|[^\"'>;&|\\n\\\\$`]|(?<=[<>])&|(?<![<>])&(?=>)|(?<=(?:^|\\s)[02-9])>{1,2}\\|?|\"[^\"]*\"|'[^']*')|(?<!\\||>|(?:^|\\s)[02-9])>{1,2}\\|?\\s*(?:\"/dev/(?:null|tty|stdout|stderr)\"|'/dev/(?:null|tty|stdout|stderr)'|/dev/(?:null|tty|stdout|stderr))(?=[\\s;&|]|$))*(?<!\\||>|(?:^|\\s)[02-9])>{1,2}\\|?\\s*(?!(?:\"/dev/(?:null|tty|stdout|stderr)\"|'/dev/(?:null|tty|stdout|stderr)'|/dev/(?:null|tty|stdout|stderr))(?:[\\s;&|]|$))[$\\w./~\"'-]",
    tool: "write",
    message:
      "Use the `write` tool instead of echo/cat redirection. `write` replaces the whole file; to append, `insert` after its last line.",
  },
  {
    pattern: "^\\s*nohup\\s+|(?<!&)\\&\\s*$",
    tool: "bg_run",
    message: "Use `bg_run` instead of nohup or background shell syntax so the job stays observable and managed.",
  },
  {
    pattern:
      "^\\s*(?:(?:bun|npm|pnpm|yarn)\\s+(?:run\\s+)?(?:dev|start)(?:\\s|$)|(?:vite|next\\s+dev|nuxt\\s+dev|nodemon|lldb|gdb|tail\\s+-f)(?:\\s|$)|docker\\s+compose\\s+up(?!.*(?:\\s-d(?:\\s|$)|--detach))(?:\\s|$))",
    tool: "bg_run",
    message: "Use `bg_run` for services, watchers, and debuggers; check them with `bg_status`.",
  },
  {
    pattern:
      "^\\s*(?:(?:bun|npm|pnpm|yarn)\\s+(?:run\\s+)?\\S+|cargo\\s+watch|watchexec|pytest|vitest|jest|tsc)(?:.|\\n)*(?:--watch|-w)(?:\\s|$)",
    tool: "bg_run",
    message: "Use `bg_run` for watch mode so its output and lifecycle stay managed.",
  },
];

const compiled = RULES.map((rule) => ({ rule, regex: new RegExp(rule.pattern) }));

/** Finds the end of a shell word, respecting quotes and escapes; returns null for incomplete syntax. */
function skipShellWord(command: string, start: number): number | null {
  let inSingle = false;
  let inDouble = false;
  for (let i = start; i < command.length; i++) {
    const ch = command[i];
    if (inSingle) {
      if (ch === "'") inSingle = false;
      continue;
    }
    if (inDouble) {
      if (ch === "\\") {
        if (i + 1 >= command.length) return null;
        i++;
        continue;
      }
      if (ch === '"') inDouble = false;
      continue;
    }
    if (ch === "'") {
      inSingle = true;
      continue;
    }
    if (ch === '"') {
      inDouble = true;
      continue;
    }
    if (ch === "\\") {
      if (i + 1 >= command.length) return null;
      i++;
      continue;
    }
    if (ch === " " || ch === "\t") return i;
  }
  return inSingle || inDouble ? null : command.length;
}

/** Removes leading `NAME=value` assignments without interpreting shell syntax. */
function withoutLeadingEnvironmentAssignments(command: string): string | null {
  let index = 0;
  let foundAssignment = false;
  while (index < command.length) {
    while (command[index] === " " || command[index] === "\t") index++;
    const assignmentStart = index;
    if (!/[A-Za-z_]/.test(command[index] ?? "")) break;
    let nameEnd = index + 1;
    while (/[A-Za-z0-9_]/.test(command[nameEnd] ?? "")) nameEnd++;
    if (command[nameEnd] !== "=") {
      return foundAssignment ? command.slice(assignmentStart).trimStart() : null;
    }
    const wordEnd = skipShellWord(command, nameEnd + 1);
    if (wordEnd === null) return null;
    foundAssignment = true;
    index = wordEnd;
    if (index === command.length) return null;
  }
  if (!foundAssignment) return null;
  const commandWithoutAssignments = command.slice(index).trimStart();
  return commandWithoutAssignments.length > 0 ? commandWithoutAssignments : null;
}

function interceptionCandidates(command: string): string[] {
  const candidates = [command.trim()];
  for (const segment of extractFlatShellCommandSegments(command)) {
    // A segment that consumes the previous stage's stdout via `|` reads piped
    // stdin, which no path-based dedicated tool (read/grep/glob) — nor any
    // other dedicated tool — can replace, so it is not an interception
    // candidate. Standalone and first-stage commands still match.
    if (segment.pipedStdin) continue;
    candidates.push(segment.text);
    const withoutAssignments = withoutLeadingEnvironmentAssignments(segment.text);
    if (withoutAssignments) candidates.push(withoutAssignments);
  }
  return candidates;
}

/** Returns the message for the first rule matching `command` whose suggested tool is active. */
export function interception(command: string, activeTools: string[]): string | undefined {
  const candidates = interceptionCandidates(command);
  for (const { rule, regex } of compiled) {
    if (!activeTools.includes(rule.tool)) continue;
    if (candidates.some((candidate) => regex.test(candidate))) return `Blocked: ${rule.message}`;
  }
}
