// CSI sequences (colors, cursor and erase controls) and OSC sequences (hyperlinks, titles) ended by BEL or ST.
const ANSI = /\x1b\[[0-?]*[ -/]*[@-~]|\x1b\][^\x07\x1b]*(?:\x07|\x1b\\)/g;

export const stripAnsi = (text: string): string => text.replace(ANSI, "");
