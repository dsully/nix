/**
 * True for subagent facade calls routed to get_subagent_result or steer_subagent. Those have no renderer upstream,
 * so the facade prints their text in full; pi's own fallback shows a collapsible preview instead.
 */
export function usesPiFallback(toolName: string, args: unknown): boolean {
  if (toolName !== "subagent" || !args || typeof args !== "object") return false;
  const { op, agent_id, prompt, subagent_type } = args as Record<string, unknown>;
  if (op !== undefined) return op === "result" || op === "steer";
  // Mirrors the facade's prepareFacadeArguments op inference.
  return agent_id !== undefined && prompt === undefined && subagent_type === undefined;
}
