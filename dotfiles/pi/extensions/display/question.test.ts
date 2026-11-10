import { expect, test } from "bun:test";
import { answeredQuestions, askedQuestions } from "./question.js";

test("each question keeps its answer", () => {
  const pairs = answeredQuestions({
    answers: [
      { question: "Base?", kind: "option", answer: "A" },
      { question: "Scope?", kind: "multi", answer: "only these", selected: ["Silent", "Dots"] },
      { question: "Blank?", answer: "" },
    ],
  });
  expect(pairs).toEqual([
    { question: "Base?", answer: "A" },
    { question: "Scope?", answer: "Silent, Dots · only these" },
    { question: "Blank?", answer: undefined },
  ]);
});

test("a cancelled ask is declined", () => {
  expect(answeredQuestions({ cancelled: true, answers: [] })).toBe("declined");
});

test("results without answers are not question blocks", () => {
  expect(answeredQuestions({ content: "x" })).toBeUndefined();
  expect(answeredQuestions(undefined)).toBeUndefined();
});

test("asked questions come from the call arguments", () => {
  expect(askedQuestions({ questions: [{ question: "One?" }, { header: "x" }] })).toEqual(["One?"]);
});
