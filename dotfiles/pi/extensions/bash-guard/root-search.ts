const START = String.raw`(?:^|[;&|(\x60\n]\s*|\b(?:sudo|xargs|exec|command|time|nice)\s+)`;

const TOOLS = "find|fd|rg|grep";
const PATH = "/(?:nix(?:/store)?/?)?";

// A path in quotes counts only as its own word, so `rg 'find /' docs` searches docs, not /.
const BROAD_SEARCH = new RegExp(
  `${START}(?:${TOOLS})\\b[^;&|\\n)]*?(?:\\s|--(?:search-path|base-directory)=)(?:'${PATH}\\*?'|"${PATH}\\*?"|${PATH}\\*?)(?=[\\s;&|)\\x60]|$)`,
);

// shortcut: misses paths reached indirectly (`cd / && find .`, variables); fine as a guard against habit, not a sandbox.
export const searchesTooBroadly = (command: string): boolean => BROAD_SEARCH.test(command);
