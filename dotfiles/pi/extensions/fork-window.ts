import { existsSync, rmSync } from "node:fs";
import { basename } from "node:path";
import type { UserMessage } from "@earendil-works/pi-ai";
import { SessionManager, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { errorMessage } from "./lib/error";
import { openWindow, selectWindow } from "./lib/rex";

const userText = (content: UserMessage["content"]): string =>
  typeof content === "string" ? content : content.flatMap((part) => (part.type === "text" ? [part.text] : [])).join("");

export default function (pi: ExtensionAPI) {
  pi.on("session_start", (_event, ctx) => {
    const draft = process.env.PI_FORK_DRAFT;
    if (draft === undefined) return;
    delete process.env.PI_FORK_DRAFT;
    ctx.ui.setEditorText(draft);
  });

  pi.on("session_before_fork", async (event, ctx) => {
    const { REX_SESSION } = process.env;
    const source = ctx.sessionManager.getSessionFile();
    const selected = ctx.sessionManager.getEntry(event.entryId);
    if (!REX_SESSION || !source || !existsSync(source) || !selected) return;

    const draft =
      event.position === "before" && selected.type === "message" && selected.message.role === "user"
        ? userText(selected.message.content)
        : undefined;
    const targetLeafId = draft === undefined ? selected.id : selected.parentId;
    if (!targetLeafId) return;

    const copy = SessionManager.open(source, ctx.sessionManager.getSessionDir());
    const file = copy.createBranchedSession(targetLeafId);
    if (!file || !existsSync(file)) return;
    const kind = event.position === "at" ? "clone" : "fork";
    const name = `${kind}: ${(pi.getSessionName() ?? basename(ctx.cwd)).replace(/^(fork|clone): /, "")}`;
    copy.appendSessionInfo(name);

    let window_id: string;
    try {
      ({ window_id } = await openWindow(REX_SESSION, ctx.cwd, [
        ...(draft === undefined ? [] : ["env", `PI_FORK_DRAFT=${draft}`]),
        "pi",
        "--session",
        file,
      ]));
    } catch (e) {
      rmSync(file);
      ctx.ui.notify(`Fork window: ${errorMessage(e)}. Forking in this pane instead.`, "error");
      return;
    }

    await selectWindow(REX_SESSION, window_id).catch((e) =>
      ctx.ui.notify(`Fork window opened, but Rex could not switch to it: ${errorMessage(e)}`, "warning"),
    );
    return { cancel: true };
  });
}
