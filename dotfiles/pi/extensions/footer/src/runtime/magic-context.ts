/**
 * magic-context publishes its own pressure reading as a pi status line:
 * `mc: 92.4K (11%) · idle`. Its numerator is prompt tokens only (no output) and
 * its denominator is the output-reserved usable window, which is what its
 * historian threshold and emergency wall are measured against. Pi's
 * `getContextUsage()` adds output tokens and divides by the raw catalog window,
 * so it reads 12-15% low relative to this. Prefer this figure when it is present.
 */
export const MAGIC_CONTEXT_STATUS_KEY = "magic-context";

const STATUS = /^mc:\s*([\d.]+)\s*([KM]?)\s*\(([\d.]+)%\)/;

export interface StatusUsage {
  tokens: number;
  percent: number;
}

export function parseMagicContextStatus(text: string | undefined): StatusUsage | undefined {
  const match = STATUS.exec(text?.trim() ?? "");
  if (!match) return undefined;
  const value = Number.parseFloat(match[1] ?? "");
  const scale = match[2] === "M" ? 1_000_000 : match[2] === "K" ? 1000 : 1;
  const percent = Number.parseFloat(match[3] ?? "");
  // `mc: -- (--) · idle` before the first reading; 0% parses from rounding noise.
  if (!Number.isFinite(value) || !Number.isFinite(percent) || percent <= 0) return undefined;
  return { tokens: Math.round(value * scale), percent };
}
