import { performance } from "node:perf_hooks";
import type { ExtensionAPI, ExtensionContext, ReadonlyFooterDataProvider } from "@earendil-works/pi-coding-agent";
import { PromptStash } from "../input/stash.js";
import { FooterEditor } from "../surface/editor.js";
import { Footer } from "../surface/footer.js";
import { RuntimeRefreshSession } from "./refresh-session.js";

export interface DraftStore {
	loadDraft(sessionId: string): string | null;
	saveDraft(sessionId: string, text: string | null): void;
}

type EditorFactory = NonNullable<ReturnType<ExtensionContext["ui"]["getEditorComponent"]>>;

export function registerFooter(pi: ExtensionAPI, drafts: DraftStore): void {
	let footerData: Pick<ReadonlyFooterDataProvider, "getGitBranch"> | undefined;
	let footer: Footer | undefined;
	let ownedEditorFactory: EditorFactory | undefined;
	let previousEditorFactory: EditorFactory | undefined;
	let requestRender: (() => void) | undefined;
	let activeEditor: FooterEditor | undefined;
	let stash: PromptStash | undefined;
	let uiGeneration = 0;

	const refreshSession = new RuntimeRefreshSession({
		getThinkingLevel: () => pi.getThinkingLevel(),
		getBranch: () => footerData?.getGitBranch() ?? null,
		nowMs: () => performance.now(),
		requestRender: () => requestRender?.(),
	});

	function setUiRequestRender(generation: number, callback: () => void): void {
		if (generation !== uiGeneration) return;
		requestRender = () => {
			if (generation === uiGeneration) callback();
		};
	}

	function invalidateUiOwnership(): number {
		activeEditor?.dispose();
		activeEditor = undefined;
		uiGeneration++;
		requestRender = undefined;
		footerData = undefined;
		footer?.dispose();
		footer = undefined;
		return uiGeneration;
	}

	function clearUI(ctx: ExtensionContext): void {
		if (ctx.mode !== "tui") return;
		const hadFooter = footer !== undefined;
		invalidateUiOwnership();
		const ownedFactory = ownedEditorFactory;
		if (ownedFactory) {
			const restoreFactory = previousEditorFactory;
			ownedEditorFactory = undefined;
			previousEditorFactory = undefined;
			if (ctx.ui.getEditorComponent() === ownedFactory) ctx.ui.setEditorComponent(restoreFactory);
		}
		if (hadFooter) ctx.ui.setFooter(undefined);
	}

	function installInputSurface(ctx: ExtensionContext): void {
		if (ctx.mode !== "tui") return;
		const initialState = refreshSession.ensureState(ctx);
		const generation = invalidateUiOwnership();

		ctx.ui.setFooter((tui, _theme, data) => {
			const unsubscribe = data.onBranchChange(() => {
				if (generation === uiGeneration) refreshSession.branchChanged(data.getGitBranch());
			});
			const nextFooter = new Footer(() => {
				unsubscribe();
				if (generation === uiGeneration && footer === nextFooter) {
					footerData = undefined;
					footer = undefined;
				}
			});
			if (generation === uiGeneration) {
				footerData = data;
				setUiRequestRender(generation, () => tui.requestRender());
				footer = nextFooter;
				refreshSession.branchChanged(data.getGitBranch());
			}
			return nextFooter;
		});

		const currentEditorFactory = ctx.ui.getEditorComponent();
		if (currentEditorFactory !== ownedEditorFactory) previousEditorFactory = currentEditorFactory;
		const nextEditorFactory: EditorFactory = (tui, theme, keybindings) => {
			if (generation === uiGeneration) activeEditor?.dispose();
			setUiRequestRender(generation, () => tui.requestRender());
			const editor = new FooterEditor(
				tui,
				theme,
				keybindings,
				() => generation === uiGeneration ? refreshSession.ensureState(ctx) : initialState,
				{ stash, getTheme: () => ctx.ui.theme, onStashError: message => ctx.ui.notify(message, "warning") },
			);
			if (generation === uiGeneration) activeEditor = editor;
			return editor;
		};
		ownedEditorFactory = nextEditorFactory;
		ctx.ui.setEditorComponent(nextEditorFactory);
	}

	function openStash(ctx: ExtensionContext): PromptStash | undefined {
		if (ctx.mode !== "tui") return undefined;
		const sessionId = ctx.sessionManager.getSessionId();
		const persistent = ctx.sessionManager.getSessionFile() !== undefined;
		try {
			return new PromptStash(persistent ? drafts.loadDraft(sessionId) : null, text => {
				if (persistent) drafts.saveDraft(sessionId, text);
			});
		} catch {
			ctx.ui.notify("Could not read the saved draft. Stash is unavailable until /reload; the file was kept.", "warning");
			return undefined;
		}
	}

	pi.on("session_start", (_event, ctx) => {
		stash = openStash(ctx);
		refreshSession.sessionStart(ctx);
		installInputSurface(ctx);
	});
	pi.on("session_shutdown", (_event, ctx) => {
		refreshSession.sessionShutdown();
		clearUI(ctx);
	});
	pi.on("model_select", (_event, ctx) => refreshSession.modelSelect(ctx));
	pi.on("thinking_level_select", (_event, ctx) => refreshSession.thinkingLevelSelect(ctx));
	pi.on("turn_start", (_event, ctx) => refreshSession.turnStart(ctx));
	pi.on("tool_execution_end", (_event, ctx) => refreshSession.lifecycle(ctx));
	pi.on("session_tree", (_event, ctx) => refreshSession.sessionTree(ctx));
	pi.on("session_compact", (event, ctx) => refreshSession.sessionCompact(event, ctx));
	pi.on("before_provider_request", () => refreshSession.providerRequest());
	pi.on("ui_prompt_start", () => refreshSession.uiPromptStart());
	pi.on("ui_prompt_end", () => refreshSession.uiPromptEnd());
	pi.on("message_end", (event, ctx) => refreshSession.messageEnd(event, ctx));
	pi.on("turn_end", (_event, ctx) => refreshSession.lifecycle(ctx));
	pi.on("agent_start", () => refreshSession.agentStart());
	pi.on("agent_end", (_event, ctx) => refreshSession.lifecycle(ctx));
	pi.on("agent_settled", (_event, ctx) => refreshSession.agentSettled(ctx));
}
