export type Answered = { question: string; answer: string | undefined };

function record(value: unknown): Record<string, unknown> | undefined {
  return typeof value === "object" && value !== null && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : undefined;
}

function answerOf(entry: Record<string, unknown>): string | undefined {
  const selected = Array.isArray(entry.selected)
    ? entry.selected.filter((s): s is string => typeof s === "string" && !!s)
    : [];
  const typed = typeof entry.answer === "string" && entry.answer.trim() ? entry.answer.trim() : undefined;
  if (!selected.length) return typed;
  const picked = selected.join(", ");
  return typed && typed !== picked ? `${picked} · ${typed}` : picked;
}

/**
 * The question and answer pairs of a result shaped like ask_user_question's, so any tool
 * with `answers: [{ question, answer | selected }]` renders as a question block.
 */
export function answeredQuestions(details: unknown): Answered[] | "declined" | undefined {
  const d = record(details);
  if (!d) return undefined;
  if (d.cancelled === true) return "declined";
  if (!Array.isArray(d.answers)) return undefined;
  const pairs = d.answers.flatMap((entry) => {
    const e = record(entry);
    return e && typeof e.question === "string" ? [{ question: e.question, answer: answerOf(e) }] : [];
  });
  return pairs.length ? pairs : undefined;
}

/** Questions from the call's arguments, for the row shown while the user answers. */
export function askedQuestions(args: unknown): string[] {
  const questions = record(args)?.questions;
  if (!Array.isArray(questions)) return [];
  return questions.flatMap((q) => {
    const text = record(q)?.question;
    return typeof text === "string" ? [text] : [];
  });
}
