export type Thought = { line?: string; ms?: number; live: boolean };

/** The thoughts of one turn, in message order; the first message that thought draws the turn's only thought line. */
export class Turn {
  private thoughts = new Map<number, Thought>();
  /** The label the head last drew, so later rounds redraw it only when it changes. */
  shown: string | undefined;

  set(message: number, thought: Thought): void {
    this.thoughts.set(message, thought);
  }

  head(): number | undefined {
    return this.thoughts.keys().next().value;
  }

  /** The newest thought's line, the time spent across them all, and whether one is still running. */
  summary(): { line?: string; live: boolean; ms?: number; count: number } {
    const all = [...this.thoughts.values()];
    const timed = all.filter((t) => t.ms !== undefined);
    const latest = all.findLast((t) => t.line) ?? all.at(-1);
    return {
      line: latest?.line,
      live: all.at(-1)?.live ?? false,
      ms: timed.length ? timed.reduce((sum, t) => sum + t.ms!, 0) : undefined,
      count: all.length,
    };
  }
}

/** Assistant messages, keyed by timestamp, grouped into turns that a user message starts. */
export class Turns {
  private byMessage = new Map<number, Turn>();
  private current: Turn | undefined;

  start(): void {
    this.current = undefined;
  }

  clear(): void {
    this.byMessage.clear();
    this.current = undefined;
  }

  get(message: number): Turn | undefined {
    return this.byMessage.get(message);
  }

  assign(message: number): Turn {
    const known = this.byMessage.get(message);
    if (known) return known;
    this.current ??= new Turn();
    this.byMessage.set(message, this.current);
    return this.current;
  }
}
