/**
 * Members the frame does not define go to the inner editor: pi wires callbacks and
 * action handlers onto the editor by duck typing, so they must land there.
 */
export function forwardToInner<T extends object>(frame: T, inner: object): T {
  const target = inner as Record<PropertyKey, unknown>;
  return new Proxy(frame, {
    get(own, prop, receiver) {
      if (prop in own) return Reflect.get(own, prop, receiver);
      const value = target[prop];
      return typeof value === "function" ? value.bind(inner) : value;
    },
    set(own, prop, value, receiver) {
      if (prop in own) return Reflect.set(own, prop, value, receiver);
      target[prop] = value;
      return true;
    },
    has: (own, prop) => prop in own || prop in target,
    // Lets outer layers wrap a callback with Object.defineProperty, as resume-sessions does with onSubmit.
    defineProperty: (own, prop, descriptor) => Reflect.defineProperty(prop in own ? own : target, prop, descriptor),
  });
}
