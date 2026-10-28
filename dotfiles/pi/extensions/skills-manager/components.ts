import {
  Container,
  type Component,
  type Input,
  Key,
  Markdown,
  matchesKey,
  Spacer,
  Text,
  truncateToWidth,
  visibleWidth,
} from "@earendil-works/pi-tui";
import { getMarkdownTheme, type Theme } from "@earendil-works/pi-coding-agent";
import { buildFrontmatterBlock, readSkillBody, type SkillBody } from "./format.js";
import { glyphs } from "./glyphs.js";
import { isDeletableSkill, isTogglableSkill } from "./registry.js";
import {
  inlineLine,
  packageLabel,
  padAnsi,
  renderFrame,
  skillEntityTitle,
  skillKeyHints,
  skillSelectedLine,
} from "./ui.js";
import type { SkillEntry } from "./types.js";

export class ListLineText implements Component {
  private readonly text: string;
  private readonly selected: boolean;
  private readonly theme: Theme;
  private readonly ellipsis: string;
  constructor(text: string, selected: boolean, theme: Theme, ellipsis = "...") {
    this.text = text;
    this.selected = selected;
    this.theme = theme;
    this.ellipsis = ellipsis;
  }
  render(width: number): string[] {
    const line = truncateToWidth(inlineLine(this.text), width, this.ellipsis);
    return [this.selected ? skillSelectedLine(this.theme, line, width) : line];
  }
  invalidate(): void {}
}

export class SearchInputLine implements Component {
  private readonly input: Input;
  private readonly theme: Theme;
  private readonly prefix: string;
  constructor(input: Input, theme: Theme, prefix = " ") {
    this.input = input;
    this.theme = theme;
    this.prefix = prefix;
  }
  render(width: number): string[] {
    const inputWidth = Math.max(1, width - visibleWidth(this.prefix));
    const line = truncateToWidth(`${this.prefix}${this.input.render(inputWidth)[0] ?? ""}`, width, "");
    return [this.theme.bg("toolPendingBg", padAnsi(line, width))];
  }
  invalidate(): void {
    this.input.invalidate();
  }
}

export class ScrollableSkillPreview implements Component {
  private scrollOffset = 0;
  private lastInnerWidth = 1;
  // The laid-out preview for one inner width. Pi calls invalidate() when the
  // theme changes and setSkill() replaces the content, and both drop it.
  private layout: { innerWidth: number; lines: string[] } | undefined;
  private skill: SkillEntry;
  private readonly theme: Theme;
  private readonly getTerminalRows: () => number;
  private body: SkillBody;
  constructor(skill: SkillEntry, theme: Theme, getTerminalRows: () => number) {
    this.skill = skill;
    this.body = readSkillBody(skill);
    this.theme = theme;
    this.getTerminalRows = getTerminalRows;
  }
  setSkill(skill: SkillEntry): void {
    this.skill = skill;
    this.body = readSkillBody(skill);
    this.scrollOffset = 0;
    this.layout = undefined;
  }
  invalidate(): void {
    this.layout = undefined;
  }
  private maxHeight(): number {
    return Math.max(10, Math.floor(this.getTerminalRows() * 0.78));
  }
  private contentLines(innerWidth: number): string[] {
    this.lastInnerWidth = innerWidth;
    if (this.layout?.innerWidth !== innerWidth) this.layout = { innerWidth, lines: this.buildContentLines(innerWidth) };
    return this.layout.lines;
  }
  private buildContentLines(innerWidth: number): string[] {
    const content = new Container();
    const status = this.skill.enabled ? this.theme.fg("success", "enabled") : this.theme.fg("warning", "disabled");
    const source = packageLabel(this.skill) ? `${packageLabel(this.skill)}` : this.skill.path;
    content.addChild(new Text(skillEntityTitle(this.theme, this.skill.name), 0, 0));
    content.addChild(
      new Text(
        `${this.theme.fg("muted", this.skill.group)}${this.theme.fg("dim", ` ${glyphs().bullet.trim()} `)}${this.theme.fg("muted", source)}${this.theme.fg("dim", ` ${glyphs().bullet.trim()} `)}${status}`,
        0,
        0,
      ),
    );
    content.addChild(new Spacer(1));
    content.addChild(new Text(this.theme.fg("muted", this.theme.bold("Description")), 0, 0));
    content.addChild(new Text(this.skill.description, 0, 0));
    content.addChild(new Spacer(1));
    content.addChild(new Text(this.theme.fg("muted", this.theme.bold("Metadata")), 0, 0));
    content.addChild(new Text(this.theme.fg("dim", buildFrontmatterBlock(this.skill)), 0, 0));
    content.addChild(new Spacer(1));
    content.addChild(new Text(this.theme.fg("muted", this.theme.bold("Content")), 0, 0));
    content.addChild(new Spacer(1));
    content.addChild(this.renderBody());
    return content.render(innerWidth);
  }
  private renderBody(): Component {
    switch (this.body.kind) {
      case "body":
        return new Markdown(this.body.text || this.theme.fg("dim", "(empty skill body)"), 0, 0, getMarkdownTheme());
      case "unreadable":
        return new Text(this.theme.fg("error", `Cannot read ${this.skill.path}: ${this.body.reason}`), 0, 0);
      default: {
        const unhandled: never = this.body;
        throw new Error(`unhandled skill body: ${JSON.stringify(unhandled)}`);
      }
    }
  }
  private footer(innerWidth: number, visibleHeight: number, totalLines: number): string {
    const maxScroll = Math.max(0, totalLines - visibleHeight);
    const scroll =
      maxScroll > 0
        ? this.theme.fg(
            "dim",
            ` ${glyphs().bullet.trim()} ${this.scrollOffset + 1}-${Math.min(totalLines, this.scrollOffset + visibleHeight)}/${totalLines}`,
          )
        : "";
    const hints: Array<[string, string]> = [["-/=", "page"]];
    if (isTogglableSkill(this.skill)) hints.push(["ctrl+x", "toggle"]);
    if (isDeletableSkill(this.skill)) hints.push(["backspace", "delete"]);
    return truncateToWidth(`${skillKeyHints(this.theme, hints)}${scroll}`, innerWidth, this.theme.fg("dim", "..."));
  }
  render(width: number): string[] {
    if (width < 8) return [];
    const innerWidth = Math.max(1, width - 4);
    const visibleHeight = Math.max(1, this.maxHeight() - 3);
    const contentLines = this.contentLines(innerWidth);
    const maxScroll = Math.max(0, contentLines.length - visibleHeight);
    this.scrollOffset = Math.max(0, Math.min(this.scrollOffset, maxScroll));
    const visible = contentLines.slice(this.scrollOffset, this.scrollOffset + visibleHeight);
    return renderFrame(this.theme, width, [...visible, this.footer(innerWidth, visibleHeight, contentLines.length)]);
  }
  handleInput(data: string): void {
    const visibleHeight = Math.max(1, this.maxHeight() - 3);
    const total = this.contentLines(this.lastInnerWidth).length;
    const maxScroll = Math.max(0, total - visibleHeight);
    if (matchesKey(data, Key.up)) this.scrollOffset = Math.max(0, this.scrollOffset - 1);
    else if (matchesKey(data, Key.down)) this.scrollOffset = Math.min(maxScroll, this.scrollOffset + 1);
    else if (matchesKey(data, "-") || matchesKey(data, Key.pageUp))
      this.scrollOffset = Math.max(0, this.scrollOffset - visibleHeight);
    else if (matchesKey(data, "=") || matchesKey(data, Key.pageDown))
      this.scrollOffset = Math.min(maxScroll, this.scrollOffset + visibleHeight);
    else if (matchesKey(data, Key.home)) this.scrollOffset = 0;
    else if (matchesKey(data, Key.end)) this.scrollOffset = maxScroll;
  }
}
