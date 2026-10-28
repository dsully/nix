import { expect, test } from "bun:test";
import { forwardToInner } from "./forward.js";

test("accessors defined through the proxy wrap the inner editor's own callbacks", () => {
  const inner = {
    onSubmit: undefined as ((text: string) => void) | undefined,
    submit(text: string) {
      this.onSubmit?.(text);
    },
  };
  const frame = forwardToInner({ own: 1 }, inner) as unknown as typeof inner;

  let wrapped: ((text: string) => void) | undefined;
  Object.defineProperty(frame, "onSubmit", {
    configurable: true,
    get: () => wrapped && ((text: string) => wrapped?.(text.toUpperCase())),
    set: (fn) => {
      wrapped = fn;
    },
  });
  const seen: string[] = [];
  frame.onSubmit = (text) => seen.push(text);
  inner.submit("hi");

  expect(seen).toEqual(["HI"]);
});
