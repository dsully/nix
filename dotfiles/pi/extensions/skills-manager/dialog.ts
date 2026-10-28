import {
  Container,
  type Focusable,
  Input,
  Key,
  matchesKey,
  Spacer,
  Text,
  type TUI,
  wrapTextWithAnsi,
} from "@earendil-works/pi-tui";
import type { ExtensionContext, Theme } from "@earendil-works/pi-coding-agent";
import { ListLineText, ScrollableSkillPreview, SearchInputLine } from "./components.js";
import { DEFAULT_LIST_ROWS, DEFAULT_POPUP_MAX_HEIGHT, DEFAULT_POPUP_WIDTH } from "./constants.js";
import { glyphs } from "./glyphs.js";
import { responsiveBrowsePageSelection, responsiveBrowseWindow } from "./layout.js";
import { isDeletableSkill, isTogglableSkill, skillStorageTarget } from "./registry.js";
import { packageLabel, renderCenteredDialog, renderFrame, skillEntityTitle, skillKeyHints } from "./ui.js";
import {
  type Mode,
  type SkillEntry,
  type SkillRegistry,
  type SkillSection,
  type SkillsManagerOptions,
  skillSection,
  sortSkillsBySection,
} from "./types.js";

class SkillsManagerDialog implements Focusable {
  private readonly ctx: ExtensionContext;
  private readonly theme: Theme;
  private readonly tui: TUI;
  private readonly done: (skill: SkillEntry | null) => void;
  private readonly options: SkillsManagerOptions;
  private readonly requestRender: () => void;
  private mode: Mode = "browse";
  private _focused = false;
  private registry!: SkillRegistry;
  // Built once per catalog load, so a keystroke matches these strings and a
  // frame reads this count instead of walking every skill entry.
  private searchIndex: Array<{ skill: SkillEntry; text: string }> = [];
  private enabledCount = 0;
  private filteredSkills: SkillEntry[] = [];
  // The browse list as drawn: each section's name, then its skills; null is the blank line between sections.
  private rows: Array<SkillSection | SkillEntry | null> = [];
  private selectedIndex = 0;
  private browseQuery = "";
  private readonly browseInput = new Input();
  private previewSkillPath: string | undefined;
  private preview: ScrollableSkillPreview | undefined;
  private deleteSkillPath: string | undefined;
  private deleteReturnMode: "browse" | "preview" = "browse";

  constructor(
    ctx: ExtensionContext,
    registry: SkillRegistry,
    theme: Theme,
    tui: TUI,
    done: (skill: SkillEntry | null) => void,
    options: SkillsManagerOptions,
    requestRender: () => void,
  ) {
    this.ctx = ctx;
    this.theme = theme;
    this.tui = tui;
    this.done = done;
    this.options = options;
    this.requestRender = requestRender;
    this.setRegistry(registry);
    this.refreshBrowseList();
  }

  get focused(): boolean {
    return this._focused;
  }
  set focused(value: boolean) {
    this._focused = value;
    this.syncFocus();
  }
  invalidate(): void {
    this.browseInput.invalidate();
    this.preview?.invalidate();
  }

  private syncFocus(): void {
    this.browseInput.focused = this._focused && this.mode === "browse";
  }

  private setRegistry(registry: SkillRegistry): void {
    this.registry = registry;
    this.searchIndex = registry.allSkills.map((skill) => ({
      skill,
      text: [
        skill.name,
        skill.description,
        skillSection(skill),
        skill.origin,
        skill.source,
        skill.path,
        skill.baseDir ?? "",
      ]
        .join(" ")
        .toLowerCase(),
    }));
    this.enabledCount = registry.allSkills.filter((skill) => skill.enabled).length;
  }

  private filterSkills(query: string): SkillEntry[] {
    const trimmed = query.trim().toLowerCase();
    if (!trimmed) return this.registry.allSkills;
    const tokens = trimmed.split(/\s+/).filter(Boolean);
    return this.searchIndex
      .filter(({ text }) => tokens.every((token) => text.includes(token)))
      .map(({ skill }) => skill);
  }

  private refreshBrowseList(preferredPath?: string): void {
    const currentPath = preferredPath ?? this.getSelectedSkill()?.path;
    this.filteredSkills = sortSkillsBySection(this.filterSkills(this.browseQuery));
    this.rows = [];
    let previous: SkillSection | undefined;
    for (const skill of this.filteredSkills) {
      const section = skillSection(skill);
      if (section !== previous) {
        if (previous) this.rows.push(null);
        this.rows.push((previous = section));
      }
      this.rows.push(skill);
    }
    if (currentPath) {
      const nextIndex = this.filteredSkills.findIndex((skill) => skill.path === currentPath);
      if (nextIndex >= 0) {
        this.selectedIndex = nextIndex;
        return;
      }
    }
    this.selectedIndex = Math.min(this.selectedIndex, Math.max(0, this.filteredSkills.length - 1));
  }

  private getSelectedSkill(): SkillEntry | undefined {
    return this.filteredSkills[this.selectedIndex];
  }
  private getDeleteSkill(): SkillEntry | undefined {
    return this.deleteSkillPath
      ? this.registry.allSkills.find((skill) => skill.path === this.deleteSkillPath)
      : undefined;
  }
  private getCurrentSkill(): SkillEntry | undefined {
    return this.previewSkillPath
      ? this.registry.allSkills.find((skill) => skill.path === this.previewSkillPath)
      : undefined;
  }

  private exitToBrowse(preferredPath?: string): void {
    this.mode = "browse";
    this.previewSkillPath = undefined;
    this.preview = undefined;
    this.deleteSkillPath = undefined;
    this.browseInput.setValue(this.browseQuery);
    this.refreshBrowseList(preferredPath);
    this.syncFocus();
    this.requestRender();
  }
  private openPreview(skill: SkillEntry): void {
    this.previewSkillPath = skill.path;
    this.preview = new ScrollableSkillPreview(skill, this.theme, () => this.tui.terminal.rows);
    this.mode = "preview";
    this.syncFocus();
    this.requestRender();
  }
  private openDeleteConfirm(skill: SkillEntry, returnMode: "browse" | "preview"): void {
    this.deleteSkillPath = skill.path;
    this.deleteReturnMode = returnMode;
    this.mode = "delete-confirm";
    this.syncFocus();
    this.requestRender();
  }
  private insertSkill(skill: SkillEntry): void {
    if (!skill.enabled) this.ctx.ui.notify("Enable this skill first with ctrl+x", "info");
    else this.done(skill);
  }

  private async refreshRegistry(preferredPath?: string): Promise<void> {
    this.setRegistry(await this.options.onRefresh());
    this.refreshBrowseList(preferredPath);
    if (this.previewSkillPath) {
      const current = this.registry.allSkills.find((skill) => skill.path === this.previewSkillPath);
      if (!current) {
        this.exitToBrowse(preferredPath);
        return;
      }
      this.preview?.setSkill(current);
    }
  }
  private async toggleSkill(skill: SkillEntry): Promise<void> {
    const nextEnabled = !skill.enabled;
    try {
      await this.options.onToggle(skill, nextEnabled);
      await this.refreshRegistry(skill.path);
      this.ctx.ui.notify(
        `${nextEnabled ? "Enabled" : "Disabled"} ${skill.name}. Run /reload to fully apply the change.`,
        "info",
      );
    } catch (error) {
      this.ctx.ui.notify(error instanceof Error ? error.message : "Failed to update skill visibility", "error");
    }
    this.requestRender();
  }
  private leaveDeleteConfirm(): void {
    this.mode = this.deleteReturnMode;
    this.syncFocus();
    this.requestRender();
  }
  // Every outcome leaves the deleting mode, which takes no input: a dialog
  // left in it could never close.
  private async confirmDelete(): Promise<void> {
    const skill = this.getDeleteSkill();
    if (!skill) {
      this.exitToBrowse();
      return;
    }
    this.mode = "deleting";
    this.syncFocus();
    this.requestRender();
    let removal: "removed" | "failed";
    try {
      removal = (await this.options.onDelete(skill)) ? "removed" : "failed";
    } catch (error) {
      this.ctx.ui.notify(
        `Cannot delete skill ${skill.name}: ${error instanceof Error ? error.message : String(error)}`,
        "error",
      );
      removal = "failed";
    }
    // A failed recursive removal can stop part-way, so the skill keeps its
    // paths and the reload decides whether it is still there.
    if (removal === "removed") {
      this.deleteSkillPath = undefined;
      this.previewSkillPath = undefined;
      this.preview = undefined;
    }
    try {
      await this.refreshRegistry();
    } catch (error) {
      const reason = error instanceof Error ? error.message : String(error);
      this.ctx.ui.notify(
        removal === "removed"
          ? `Deleted skill ${skill.name}, but the skills list did not reload: ${reason}`
          : `Cannot reload the skills list after deleting ${skill.name} failed: ${reason}`,
        "error",
      );
      this.exitToBrowse();
      return;
    }
    // Only a skill the reloaded registry still lists returns to where the
    // delete began; anything else leaves for the reloaded list.
    if (this.getDeleteSkill()) this.leaveDeleteConfirm();
    else this.exitToBrowse();
  }

  render(width: number): string[] {
    if (this.mode === "preview") return this.preview?.render(width) ?? [];
    if (this.mode === "delete-confirm") return this.renderDeleteDialog(width);
    if (this.mode === "deleting") return this.renderDeletingDialog(width);
    return this.renderBrowse(width);
  }

  private renderBrowse(width: number): string[] {
    const innerWidth = Math.max(1, width - 4);
    const root = new Container();
    const glyph = glyphs();
    root.addChild(new SearchInputLine(this.browseInput, this.theme));
    root.addChild(new Spacer(1));
    const list = new Container();
    const selected = this.getSelectedSkill();
    const { startIndex, endIndex } = responsiveBrowseWindow(
      DEFAULT_LIST_ROWS,
      this.tui.terminal.rows,
      this.rows.length,
      selected ? this.rows.indexOf(selected) : 0,
      DEFAULT_POPUP_MAX_HEIGHT,
    );
    const ellipsis = this.theme.fg("dim", "...");
    for (let i = startIndex; i < endIndex; i++) {
      const row = this.rows[i];
      if (!row) {
        list.addChild(new Spacer(1));
        continue;
      }
      if (typeof row === "string") {
        const label = row[0]!.toUpperCase() + row.slice(1);
        list.addChild(
          new ListLineText(
            `${this.theme.fg("dim", "── ")}${this.theme.fg("muted", label)} ${this.theme.fg("dim", "─".repeat(innerWidth))}`,
            false,
            this.theme,
            "",
          ),
        );
        continue;
      }
      const mark = row.enabled ? this.theme.fg("success", `(${glyph.ok})`) : this.theme.fg("muted", `(${glyph.fail})`);
      const name = row.enabled ? row.name : this.theme.fg("muted", row.name);
      const source = packageLabel(row) ? this.theme.fg("muted", ` [${packageLabel(row)}]`) : "";
      const description = this.theme.fg("dim", ` — ${row.description}`);
      list.addChild(
        new ListLineText(` ${mark} ${name}${source}${description}`, row === selected, this.theme, ellipsis),
      );
    }
    if (this.filteredSkills.length === 0)
      list.addChild(new Text(this.theme.fg("dim", "No skills match your search."), 1, 0));
    root.addChild(list);
    root.addChild(new Spacer(1));
    const actions: Array<[string, string]> = [["-/=", "page"]];
    if (selected) {
      actions.push(["tab", "preview"]);
      if (isTogglableSkill(selected)) actions.push(["ctrl+x", "toggle"]);
      if (!this.browseQuery && isDeletableSkill(selected)) actions.push(["backspace", "delete"]);
    }
    root.addChild(new Text(skillKeyHints(this.theme, actions), 1, 0));
    return renderFrame(
      this.theme,
      width,
      root.render(innerWidth),
      undefined,
      "Skills Manager",
      `${this.enabledCount}/${this.registry.allSkills.length} enabled`,
    );
  }

  private renderDeleteDialog(width: number): string[] {
    const skill = this.getDeleteSkill();
    const innerWidth = Math.max(1, Math.min(width - 4, 64));
    const message = skill
      ? `Delete ${skill.name}? This removes ${skillStorageTarget(skill)} and cannot be undone.`
      : "Delete this skill?";
    return renderCenteredDialog(this.theme, width, [
      skillEntityTitle(this.theme, "Delete skill"),
      "",
      ...wrapTextWithAnsi(message, innerWidth),
      "",
    ]);
  }
  private renderDeletingDialog(width: number): string[] {
    return renderCenteredDialog(this.theme, width, [
      skillEntityTitle(this.theme, "Deleting skill"),
      "",
      this.theme.fg("dim", "The manager continues when the removal finishes."),
    ]);
  }

  handleInput(data: string): void {
    // A removal in flight takes no input: a second confirm would delete again.
    if (this.mode === "deleting") return;
    if (this.mode === "delete-confirm") {
      if (matchesKey(data, Key.escape)) {
        this.leaveDeleteConfirm();
        return;
      }
      if (matchesKey(data, Key.enter)) void this.confirmDelete();
      return;
    }
    if (this.mode === "preview") {
      const skill = this.getCurrentSkill();
      if (!skill) {
        this.exitToBrowse();
        return;
      }
      if (matchesKey(data, Key.escape) || matchesKey(data, Key.tab)) {
        this.exitToBrowse(skill.path);
        return;
      }
      if (matchesKey(data, Key.enter)) {
        this.insertSkill(skill);
        return;
      }
      if (isTogglableSkill(skill) && (matchesKey(data, Key.alt("x")) || matchesKey(data, Key.ctrl("x")))) {
        void this.toggleSkill(skill);
        return;
      }
      if (isDeletableSkill(skill) && (matchesKey(data, Key.backspace) || matchesKey(data, "delete"))) {
        this.openDeleteConfirm(skill, "preview");
        return;
      }
      this.preview?.handleInput(data);
      return;
    }
    this.handleBrowseInput(data);
  }
  private handleBrowseInput(data: string): void {
    const last = Math.max(0, this.filteredSkills.length - 1);
    if (matchesKey(data, Key.up)) {
      this.selectedIndex = this.selectedIndex === 0 ? last : this.selectedIndex - 1;
      return;
    }
    if (matchesKey(data, Key.down)) {
      this.selectedIndex = this.selectedIndex >= last ? 0 : this.selectedIndex + 1;
      return;
    }
    if (matchesKey(data, "-") || matchesKey(data, Key.pageUp)) {
      this.selectedIndex = responsiveBrowsePageSelection(
        DEFAULT_LIST_ROWS,
        this.tui.terminal.rows,
        this.selectedIndex,
        last,
        -1,
        DEFAULT_POPUP_MAX_HEIGHT,
      );
      return;
    }
    if (matchesKey(data, "=") || matchesKey(data, Key.pageDown)) {
      this.selectedIndex = responsiveBrowsePageSelection(
        DEFAULT_LIST_ROWS,
        this.tui.terminal.rows,
        this.selectedIndex,
        last,
        1,
        DEFAULT_POPUP_MAX_HEIGHT,
      );
      return;
    }
    const skill = this.getSelectedSkill();
    if (matchesKey(data, Key.enter)) {
      if (skill) this.insertSkill(skill);
      return;
    }
    if (matchesKey(data, Key.tab)) {
      if (skill) this.openPreview(skill);
      return;
    }
    if (matchesKey(data, Key.alt("x")) || matchesKey(data, Key.ctrl("x"))) {
      if (skill && isTogglableSkill(skill)) void this.toggleSkill(skill);
      return;
    }
    if (matchesKey(data, Key.backspace) && !this.browseInput.getValue()) {
      if (skill && isDeletableSkill(skill)) this.openDeleteConfirm(skill, "browse");
      return;
    }
    if (matchesKey(data, Key.escape)) {
      if (this.browseInput.getValue()) {
        this.browseQuery = "";
        this.browseInput.setValue("");
        this.refreshBrowseList();
      } else this.done(null);
      return;
    }
    this.browseInput.handleInput(data);
    this.browseQuery = this.browseInput.getValue();
    this.refreshBrowseList();
  }
}

export async function showSkillsManager(
  ctx: ExtensionContext,
  registry: SkillRegistry,
  options: SkillsManagerOptions,
): Promise<SkillEntry | null> {
  return await ctx.ui.custom<SkillEntry | null>(
    (tui, theme, _kb, done) => {
      const dialog = new SkillsManagerDialog(ctx, registry, theme, tui, done, options, () => tui.requestRender());
      return {
        get focused() {
          return dialog.focused;
        },
        set focused(value: boolean) {
          dialog.focused = value;
        },
        render(width: number) {
          return dialog.render(width);
        },
        invalidate() {
          dialog.invalidate();
        },
        handleInput(data: string) {
          dialog.handleInput(data);
          tui.requestRender();
        },
      };
    },
    {
      overlay: true,
      overlayOptions: { anchor: "center", width: DEFAULT_POPUP_WIDTH, maxHeight: DEFAULT_POPUP_MAX_HEIGHT },
    },
  );
}
