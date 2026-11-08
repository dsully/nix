import { type ExtensionAPI } from "@earendil-works/pi-coding-agent";

const rewriteInstructions = `Rewrite the supplied original prompt for clarity, precision, and usefulness.

Requirements:
- As best you can, answer any unanswered questions in the original prompt, using tools and bash as necessary.
- Preserve the original intent.
- Improve structure, specificity, and actionability.
- Do not invent requirements.
- Output only the rewritten prompt, with no preamble or explanation.
- Include list of clarifing questions.
`;

export default function (pi: ExtensionAPI) {
  pi.registerCommand("rewrite", {
    description: "Rewrite a prompt in an ephemeral SDK session",
    argumentHint: "<prompt>",
    handler: async (args, ctx) => {
      const prompt = args.trim();
      if (!prompt) {
        ctx.ui.notify("Usage: /rewrite <prompt>", "warning");
        return;
      }

      const { createAgentSession, SessionManager } = await import("@earendil-works/pi-coding-agent");

      const { session } = await createAgentSession({
        cwd: ctx.cwd,
        sessionManager: SessionManager.inMemory(),
        tools: [],
      });

      let output = "";
      const unsubscribe = session.subscribe((event) => {
        if (event.type === "message_update" && event.assistantMessageEvent.type === "text_delta") {
          output += event.assistantMessageEvent.delta;
        }
      });

      try {
        await session.prompt(`${rewriteInstructions}\n\nOriginal prompt:\n${prompt}`);
        ctx.ui.setEditorText(output.trim());
        ctx.ui.notify("Rewritten prompt placed in the editor.", "info");
      } finally {
        unsubscribe();
        session.dispose();
      }
    },
  });
}
