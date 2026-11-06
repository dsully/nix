// pi only marks its built-in dialogs blocked (OSC 7501); rpiv-ask-user-question's ctx.ui.custom stays "working".
// The reporter has no extension API, so it is taken from InteractiveMode.handleEvent.
import { InteractiveMode, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { patchMethod } from "../lib/patch.js";

type Blocked = { kind: "question"; message?: string };
type Reporter = { setBlocked(source: string, status: Blocked | undefined): void };
type HandleEvent = (this: { programStatus?: Reporter }, event: unknown) => Promise<void>;

interface PromptEvent {
  toolCallId?: string;
  questions?: { question?: string }[];
}

interface BlockedEvent {
  active?: boolean;
  toolCallId?: string;
}

export function questionStatus(pi: ExtensionAPI) {
  let reporter: Reporter | undefined;
  const questions = new Map<string, string | undefined>();

  patchMethod<HandleEvent>(
    InteractiveMode.prototype,
    "handleEvent",
    "dsully.question-status.handleEvent",
    (original) =>
      original &&
      function (event) {
        reporter = this.programStatus;
        return original.call(this, event);
      },
  );

  pi.events.on("rpiv:ask-user:prompt", (data) => {
    const { toolCallId, questions: asked } = data as PromptEvent;
    if (toolCallId) questions.set(toolCallId, asked?.[0]?.question);
  });

  pi.events.on("rpiv:ask-user:blocked", (data) => {
    const { active, toolCallId = "" } = data as BlockedEvent;
    const message = questions.get(toolCallId);
    if (!active) questions.delete(toolCallId);
    reporter?.setBlocked(`ask-user:${toolCallId}`, active ? { kind: "question", message } : undefined);
  });
}
