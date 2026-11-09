// octet's Pi bridge throws on message fields it cannot supply, where Pi reads them as undefined.
export function field<T>(read: () => T): T | undefined {
  try {
    return read();
  } catch {
    return undefined;
  }
}
