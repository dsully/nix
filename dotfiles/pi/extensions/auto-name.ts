/**
 * Names sessions from the conversation so `pi --resume` lists real titles.
 * Ported from @optomatica/pi-auto-session-name (MIT).
 *
 *   /autoname          show the name, who set it, and the namer model
 *   /autoname refresh  regenerate the name now, even over a manual one
 *
 * PI_AUTONAME_MODEL="provider/model-id" picks the namer; default is the session model.
 * Under rex (TERM=xterm-rex) nothing is named automatically; /autoname refresh still works.
 */
import { randomUUID } from "node:crypto";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

// Same marker type as the npm package, so sessions it named stay auto-owned.
const CUSTOM_TYPE = "auto-session-name";
const MAX_TITLE_CHARS = 100;
const REFRESH_EVERY_USER_MESSAGES = 8;
const REQUEST_TIMEOUT_MS = 30_000;
const PER_MESSAGE_CHARS = 350;
const TOTAL_CHAR_BUDGET = 4_000;
const RECENT_MESSAGE_CAP = 8;

type SessionMessage = { role: "user" | "assistant"; text: string };
type AnyEntry = {
  type: string;
  customType?: string;
  data?: unknown;
  message?: { role?: string; content?: unknown };
};
type Marker = { name?: unknown; count?: unknown };

function clean(text: string): string {
  return text
    .replace(/<system-reminder>[\s\S]*?<\/system-reminder>/gi, "")
    .replace(/<selected-context>[\s\S]*?<\/selected-context>/gi, "")
    .replace(/<environment_context>[\s\S]*?<\/environment_context>/gi, "")
    .replace(/\s+/g, " ")
    .trim();
}

function joinTextParts(content: unknown): string {
  if (typeof content === "string") return content;
  if (!Array.isArray(content)) return "";
  return (content as Array<{ type?: string; text?: string }>)
    .filter((part) => part?.type === "text" && typeof part.text === "string")
    .map((part) => part.text)
    .join("\n");
}

function extractConversation(entries: AnyEntry[]): SessionMessage[] {
  const out: SessionMessage[] = [];
  for (const entry of entries) {
    if (entry.type !== "message" || !entry.message) continue;
    const role = entry.message.role;
    if (role !== "user" && role !== "assistant") continue;
    const text = clean(joinTextParts(entry.message.content));
    if (text) out.push({ role, text });
  }
  return out;
}

const truncateChars = (s: string, max: number): string => (s.length <= max ? s : `${s.slice(0, max)}…`);

function truncateWords(s: string, max: number): string {
  if (s.length <= max) return s;
  const cut = s.slice(0, max);
  const space = cut.lastIndexOf(" ");
  return (space > max * 0.5 ? cut.slice(0, space) : cut).trim();
}

function shortenTitle(raw: string): string {
  const t = clean(raw)
    .replace(/^title:\s*/i, "")
    .replace(/^["'`“”«»]+/, "")
    .replace(/["'`“”«»]+$/, "")
    .replace(/[.!?]+$/, "");
  return t ? truncateWords(t, MAX_TITLE_CHARS) : "";
}

/** First message (states the goal) plus the most recent ones, within the char budget. */
function selectForPrompt(messages: SessionMessage[]): SessionMessage[] {
  if (messages.length === 0) return [];
  const first = { role: messages[0].role, text: truncateChars(messages[0].text, PER_MESSAGE_CHARS) };
  const chosen: SessionMessage[] = [];
  let used = first.text.length;
  for (let i = messages.length - 1; i >= 1; i--) {
    const m = messages[i];
    const len = Math.min(m.text.length, PER_MESSAGE_CHARS);
    if (used + len > TOTAL_CHAR_BUDGET) continue;
    chosen.push({ role: m.role, text: truncateChars(m.text, PER_MESSAGE_CHARS) });
    used += len;
    if (chosen.length >= RECENT_MESSAGE_CAP) break;
  }
  return [first, ...chosen.reverse()];
}

function buildTitlePrompt(messages: SessionMessage[]): string {
  return [
    "You write one-line titles for coding-agent sessions, shown in a session picker.",
    "Reply with ONLY the title: a single line, no quotes, no trailing punctuation, at most 14 words and 100 characters.",
    'Describe the concrete task or topic of the session (e.g. "Fix off-by-one pagination in clients list table", "Add hasAdverseMedia flag to KYC review screen").',
    "Use the same language as the conversation.",
    "",
    "<conversation>",
    ...messages.map((m) => `${m.role === "user" ? "User" : "Assistant"}: ${m.text}`),
    "</conversation>",
  ].join("\n");
}

function resolveModel(ctx: ExtensionContext) {
  const spec = process.env.PI_AUTONAME_MODEL?.trim();
  const slash = spec?.indexOf("/") ?? -1;
  if (spec && slash > 0) {
    const model = ctx.modelRegistry.find(spec.slice(0, slash), spec.slice(slash + 1));
    if (model && ctx.modelRegistry.hasConfiguredAuth(model)) return model;
  }
  const active = ctx.model;
  return active && ctx.modelRegistry.hasConfiguredAuth(active) ? active : undefined;
}

function withTimeout<T>(promise: Promise<T>, ms: number): Promise<T> {
  return Promise.race([
    promise,
    new Promise<T>((_resolve, reject) => {
      setTimeout(() => reject(new Error("timeout")), ms).unref?.();
    }),
  ]);
}

/** Model title, or the cleaned first user message when the model is missing or fails. */
async function generateTitle(ctx: ExtensionContext, messages: SessionMessage[]): Promise<string | undefined> {
  const model = resolveModel(ctx);
  if (model) {
    try {
      const call = ctx.modelRegistry.complete(
        model,
        {
          messages: [
            {
              role: "user" as const,
              content: [{ type: "text" as const, text: buildTitlePrompt(selectForPrompt(messages)) }],
              timestamp: Date.now(),
            },
          ],
        },
        { reasoningEffort: "low", cacheRetention: "none", sessionId: randomUUID() },
      );
      call.catch(() => {});
      const response = await withTimeout(call, REQUEST_TIMEOUT_MS);
      const blocks: Array<{ type: string; text?: string }> = response.content ?? [];
      const title = shortenTitle(
        blocks
          .filter((block) => block.type === "text")
          .map((block) => block.text ?? "")
          .join(" "),
      );
      if (title.length >= 3) return title;
    } catch {
      // fall through to the first user message
    }
  }
  const firstUser = messages.find((m) => m.role === "user");
  return firstUser ? truncateWords(firstUser.text, MAX_TITLE_CHARS) : undefined;
}

export default function autoName(pi: ExtensionAPI) {
  let userOwned = false;
  let lastAutoName: string | undefined;
  let lastNamedAtCount = 0;
  let pendingOwnName: string | undefined;
  let inFlight = false;
  let generation = 0;

  const maybeName = async (ctx: ExtensionContext, force = false): Promise<void> => {
    if (inFlight || !ctx.sessionManager.getSessionFile()) return;
    const messages = extractConversation(ctx.sessionManager.getBranch() as AnyEntry[]);
    const userCount = messages.filter((m) => m.role === "user").length;
    if (userCount === 0) return;
    if (!force && (userOwned || process.env.TERM === "xterm-rex")) return;
    if (!force && lastNamedAtCount > 0 && userCount - lastNamedAtCount < REFRESH_EVERY_USER_MESSAGES) return;

    const ticket = generation;
    inFlight = true;
    try {
      const title = await generateTitle(ctx, messages);
      // A session switch or a manual /name during the call wins over this result.
      if (!title || ticket !== generation || (userOwned && !force)) return;
      userOwned = false;
      lastAutoName = title;
      lastNamedAtCount = userCount;
      if (title !== pi.getSessionName()) {
        pendingOwnName = title;
        pi.setSessionName(title);
        if (ctx.hasUI) ctx.ui.notify(`Session named: ${title}`, "info");
      }
      pi.appendEntry(CUSTOM_TYPE, { name: title, count: userCount });
    } catch {
      // naming must never break a session
    } finally {
      if (ticket === generation) inFlight = false;
    }
  };

  // print and json modes exit once the run ends, so they wait for the name to be saved.
  const run = (ctx: ExtensionContext, force = false) => {
    const naming = maybeName(ctx, force).catch(() => {});
    return ctx.mode === "print" || ctx.mode === "json" ? naming : undefined;
  };

  pi.on("session_start", async (_event, ctx) => {
    generation++;
    userOwned = false;
    lastAutoName = undefined;
    lastNamedAtCount = 0;
    pendingOwnName = undefined;
    inFlight = false;

    let marker: Marker | undefined;
    for (const entry of ctx.sessionManager.getEntries() as AnyEntry[]) {
      if (entry.type === "custom" && entry.customType === CUSTOM_TYPE && entry.data && typeof entry.data === "object") {
        marker = entry.data as Marker;
      }
    }
    if (typeof marker?.name === "string") lastAutoName = marker.name;
    if (typeof marker?.count === "number") lastNamedAtCount = marker.count;
    const current = pi.getSessionName();
    if (current && current !== lastAutoName) userOwned = true;

    if (!userOwned && lastNamedAtCount === 0) await run(ctx);
  });

  pi.on("session_info_changed", async (event) => {
    if (pendingOwnName !== undefined && event.name === pendingOwnName) {
      pendingOwnName = undefined;
      return;
    }
    userOwned = event.name !== undefined;
  });

  pi.on("agent_settled", async (_event, ctx) => {
    await run(ctx);
  });

  pi.registerCommand("autoname", {
    description: "Show the session name; /autoname refresh regenerates it",
    getArgumentCompletions: (prefix) =>
      "refresh".startsWith(prefix.trim()) ? [{ value: "refresh", label: "refresh" }] : null,
    handler: async (args, ctx) => {
      const notify = (message: string, level: "info" | "warning" = "info") => {
        if (ctx.hasUI) ctx.ui.notify(message, level);
      };
      const arg = args.trim();
      if (arg === "refresh") {
        notify("Generating session name...");
        await maybeName(ctx, true);
        return;
      }
      if (arg) {
        notify("Usage: /autoname [refresh]", "warning");
        return;
      }
      const name = pi.getSessionName();
      const owner = !name ? "" : userOwned ? " (manual)" : name === lastAutoName ? " (auto)" : "";
      const model = resolveModel(ctx);
      notify(`Session name: ${name ?? "none"}${owner} · namer: ${model ? `${model.provider}/${model.id}` : "none"}`);
    },
  });
}
