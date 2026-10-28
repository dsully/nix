const START = String.raw`(?:^|[;&|(\x60\n]\s*|\b(?:sudo|xargs|exec|command|time|nice)\s+)`;

const searchOf = (tools: string, path: string) =>
  new RegExp(
    `${START}(?:${tools})\\b[^;&|\\n)]*?(?:\\s|--(?:search-path|base-directory)=)['"]?${path}\\*?['"]?(?=[\\s;&|)\\x60]|$)`,
  );

const ROOT_SEARCH = searchOf("find|fd", "/");
const STORE_SEARCH = searchOf("find|fd|rg|grep", "/nix(?:/store)?/?");

// shortcut: misses paths reached indirectly (`cd / && find .`, variables); fine as a guard against habit, not a sandbox.
export const searchesTooBroadly = (command: string): boolean => ROOT_SEARCH.test(command) || STORE_SEARCH.test(command);
