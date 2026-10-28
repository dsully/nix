// Pi matches built-in commands in the editor's submit handler before extension commands, so a
// registered /resume never runs; rewrite the submitted text to pi-session-manager's /sessions instead.
import { CustomEditor, type ExtensionAPI, type ExtensionContext } from "@earendil-works/pi-coding-agent";

type EditorFactory = NonNullable<ReturnType<ExtensionContext["ui"]["getEditorComponent"]>>;

export default function (pi: ExtensionAPI) {
  let baseFactory: EditorFactory | undefined;
  let ownFactory: EditorFactory | undefined;

  pi.on("session_start", (_event, ctx) => {
    if (ctx.mode !== "tui") return;
    const current = ctx.ui.getEditorComponent();
    if (current !== ownFactory) baseFactory = current;
    ownFactory = (tui, theme, keybindings) => {
      const editor = baseFactory?.(tui, theme, keybindings) ?? new CustomEditor(tui, theme, keybindings);
      // pi assigns onSubmit after the factory returns, so wrap whatever it sets.
      let submit: ((text: string) => void) | undefined;
      Object.defineProperty(editor, "onSubmit", {
        configurable: true,
        get: () => submit && ((text: string) => submit?.(text.trim() === "/resume" ? "/sessions" : text)),
        set: (fn) => {
          submit = fn;
        },
      });
      return editor;
    };
    ctx.ui.setEditorComponent(ownFactory);
  });
}
