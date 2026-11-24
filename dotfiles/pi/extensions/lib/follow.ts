import { closeSync, fstatSync, openSync, readSync } from "node:fs";

/** Calls onData with what path gains from byte from on, every 500ms; the returned function reads the rest and stops. */
export function follow(path: string, from: number, onData: (d: Buffer) => void): () => void {
  let pos = from;
  const drain = () => {
    let fd: number | undefined;
    try {
      fd = openSync(path, "r");
      const size = fstatSync(fd).size;
      if (size <= pos) return;
      const buf = Buffer.alloc(size - pos);
      pos += readSync(fd, buf, 0, buf.length, pos);
      onData(buf);
    } catch {
      // Not created yet
    } finally {
      if (fd !== undefined) closeSync(fd);
    }
  };
  const timer = setInterval(drain, 500);
  return () => {
    clearInterval(timer);
    drain();
  };
}
