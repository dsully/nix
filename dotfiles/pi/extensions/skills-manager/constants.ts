export const DEFAULT_POPUP_WIDTH = "82%";
export const DEFAULT_POPUP_MAX_HEIGHT = "86%";
export const DEFAULT_LIST_ROWS = 14;

const ANSI_GREEN_FG = "\x1b[32m";
const ANSI_YELLOW_FG = "\x1b[33m";
const ANSI_FG_RESET = "\x1b[39m";

export function ansiGreen(text: string): string {
  return `${ANSI_GREEN_FG}${text}${ANSI_FG_RESET}`;
}
export function ansiYellow(text: string): string {
  return `${ANSI_YELLOW_FG}${text}${ANSI_FG_RESET}`;
}
