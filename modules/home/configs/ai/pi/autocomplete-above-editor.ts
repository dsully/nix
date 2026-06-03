import { CustomEditor, type ExtensionAPI } from "@earendil-works/pi-coding-agent";

type AutocompleteList = {
	render(width: number): string[];
};

type EditorInternals = {
	autocompleteList?: AutocompleteList;
	autocompleteState?: unknown;
	paddingX?: number;
};

class AutocompleteAboveEditor extends CustomEditor {
	render(width: number): string[] {
		const lines = super.render(width);
		const editor = this as unknown as EditorInternals;

		if (!editor.autocompleteState || !editor.autocompleteList) {
			return lines;
		}

		const maxPadding = Math.max(0, Math.floor((width - 1) / 2));
		const paddingX = Math.min(editor.paddingX ?? 0, maxPadding);
		const contentWidth = Math.max(1, width - paddingX * 2);
		const autocompleteLineCount = editor.autocompleteList.render(contentWidth).length;

		if (autocompleteLineCount <= 0 || autocompleteLineCount >= lines.length) {
			return lines;
		}

		const autocompleteLines = lines.slice(-autocompleteLineCount);
		const editorLines = lines.slice(0, -autocompleteLineCount);
		return [...autocompleteLines, ...editorLines];
	}
}

export default function autocompleteAboveEditor(pi: ExtensionAPI) {
	pi.on("session_start", (_event, ctx) => {
		if (!ctx.hasUI) return;
		ctx.ui.setEditorComponent((tui, theme, keybindings) => new AutocompleteAboveEditor(tui, theme, keybindings));
	});
}
