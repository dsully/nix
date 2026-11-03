type Method = (this: any, ...args: any[]) => any;
type Patch = { restore: () => void };

/**
 * Replaces `target[name]` with `wrap(original)`; `wrap` returns undefined to leave it alone.
 * Installing again under the same key (another session, /reload) first restores the previous wrap if it is still on top,
 * so wraps never stack and reloaded code takes effect.
 */
export function patchMethod<F extends Method>(
  target: object,
  name: string,
  key: string,
  wrap: (original: F | undefined) => F | undefined,
): () => void {
  const slots = target as Record<PropertyKey, unknown>;
  const slot = Symbol.for(key);
  (slots[slot] as Patch | undefined)?.restore();

  const own = Object.hasOwn(target, name);
  const original = slots[name] as F | undefined;
  const patched = wrap(typeof original === "function" ? original : undefined);
  if (!patched) return () => {};
  slots[name] = patched;

  const record: Patch = {
    restore() {
      if (slots[name] === patched) {
        if (own) slots[name] = original;
        else delete slots[name];
      }
      if (slots[slot] === record) delete slots[slot];
    },
  };
  slots[slot] = record;
  return record.restore;
}
