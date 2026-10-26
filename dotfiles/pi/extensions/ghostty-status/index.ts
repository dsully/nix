/**
 * Report pi's run state and session name to Ghostty.
 *
 * Titles go out as OSC 2 (window) and OSC 1 (tab). Ghostty 1.3.1 ignores
 * OSC 1, so its tab shows the OSC 2 title. OSC 9;4 is the progress mark under
 * the tab bar. OSC 7501 is the program-status protocol for terminals that
 * understand it; 1.3.1 ignores it.
 *
 * Leave terminal.showTerminalProgress off. Its keepalive rewrites OSC 9;4;3
 * and would cover the paused "waiting for you" state.
 */
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import {
  activityFromTool,
  assistantSummary,
  clearSequences,
  progressKeepalive,
  statusSequences,
  titleSequences,
  type BlockedKind,
  type StatusPhase,
  type StatusReport,
} from "./status.ts";

const TICK_MS = 200;
const KEEPALIVE_TICKS = 5;

interface Block {
  detail: string;
  kind: BlockedKind;
}

export default function ghosttyStatus(pi: ExtensionAPI) {
  let running = false;
  let compacting = false;
  let promptDepth = 0;
  let promptDetail = "";
  let promptKind: BlockedKind = "question";
  let outcome: "completed" | "aborted" | "error" = "completed";
  let summary = "";
  let activity = "";
  let folder = "pi";
  let frame = 0;
  const blocking = new Map<string, Block>();
  let timer: ReturnType<typeof setInterval> | undefined;
  let lastWritten = "";

  const report = (): StatusReport => {
    const name = pi.getSessionName();
    const block =
      promptDepth > 0
        ? { detail: promptDetail, kind: promptKind }
        : blocking.size > 0
          ? [...blocking.values()].at(-1)
          : undefined;
    if (block) return { phase: "blocked", detail: block.detail, folder, name, kind: block.kind };
    if (running || compacting)
      return { phase: "working", detail: activity || (compacting ? "📦" : "💭"), folder, name, frame };
    if (outcome === "error") return { phase: "error", detail: summary || "❌", folder, name };
    if (outcome === "completed" && summary) return { phase: "done", detail: summary, folder, name };
    return { phase: "idle", detail: "", folder, name };
  };

  const write = (force = false) => {
    if (!process.stdout.isTTY) return;
    const next = report();
    const bytes = statusSequences(next);
    if (!force && bytes === lastWritten) return;
    lastWritten = bytes;
    process.stdout.write(bytes);
    const phase: StatusPhase = next.phase;
    if (phase === "idle") stopTicker();
    else startTicker();
  };

  // Animates the spinner while working and repeats OSC 9;4, which Ghostty drops after ~15s without it.
  const startTicker = () => {
    if (timer) return;
    timer = setInterval(() => {
      if (!process.stdout.isTTY) return;
      frame++;
      const now = report();
      const title = now.phase === "working" ? titleSequences(now) : "";
      const keepalive = frame % KEEPALIVE_TICKS === 0 ? progressKeepalive(now.phase) : "";
      if (title || keepalive) process.stdout.write(title + keepalive);
    }, TICK_MS);
    timer.unref?.();
  };

  const stopTicker = () => {
    if (!timer) return;
    clearInterval(timer);
    timer = undefined;
  };

  const bind = (next: { cwd: string }) => {
    folder = next.cwd.split("/").filter(Boolean).pop() || "pi";
  };

  pi.on("session_start", async (_event, next) => {
    bind(next);
    running = false;
    compacting = false;
    promptDepth = 0;
    blocking.clear();
    outcome = "completed";
    summary = "";
    activity = "";
    write(true);
  });

  pi.on("session_shutdown", async () => {
    stopTicker();
    if (process.stdout.isTTY) process.stdout.write(clearSequences());
    lastWritten = "";
  });

  // Pi rewrites OSC 0 to "π - <name> - <cwd>" just before this event reaches extensions.
  pi.on("session_info_changed", async () => {
    write(true);
  });

  pi.on("session_before_compact", async (_event, next) => {
    bind(next);
    compacting = true;
    activity = "📦";
    write();
  });

  pi.on("session_compact", async () => {
    compacting = false;
    write();
  });

  pi.on("session_compact_failed", async () => {
    compacting = false;
    outcome = "error";
    summary = "📦";
    write();
  });

  pi.on("agent_start", async (_event, next) => {
    bind(next);
    running = true;
    outcome = "completed";
    summary = "";
    activity = "💭";
    write();
  });

  pi.on("turn_start", async (_event, next) => {
    bind(next);
    running = true;
    outcome = "completed";
    if (!activity) activity = "💭";
    write();
  });

  pi.on("tool_execution_start", async (event, next) => {
    bind(next);
    const activityReport = activityFromTool(event.toolName, event.args);
    activity = activityReport.detail;
    if (activityReport.blocked && activityReport.kind) {
      blocking.set(event.toolCallId, { detail: activityReport.detail, kind: activityReport.kind });
    }
    write();
  });

  pi.on("tool_execution_end", async (event, next) => {
    bind(next);
    blocking.delete(event.toolCallId);
    if (event.isError) activity = `❌ ${event.toolName}`;
    write();
  });

  pi.on("ui_prompt_start", async (event, next) => {
    bind(next);
    promptDepth++;
    promptDetail = event.title || (event.kind === "confirm" ? "✋" : "❓");
    promptKind = event.kind === "confirm" ? "permission" : "question";
    write();
  });

  pi.on("ui_prompt_end", async (_event, next) => {
    bind(next);
    promptDepth = Math.max(0, promptDepth - 1);
    write();
  });

  pi.on("agent_end", async (event) => {
    const text = assistantSummary(event.messages);
    if (text) summary = text;
  });

  pi.on("agent_before_settle", async (event, next) => {
    bind(next);
    outcome = event.outcome;
    write();
  });

  pi.on("agent_settled", async (_event, next) => {
    bind(next);
    running = false;
    blocking.clear();
    write();
  });
}
