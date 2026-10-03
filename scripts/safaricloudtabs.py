#!/usr/bin/env python3

"""Show Safari iCloud tab group data from SafariTabs.db."""

import csv
import re
import sqlite3
import sys

from collections import Counter, defaultdict
from collections.abc import Iterable, Sequence
from pathlib import Path
from typing import Annotated

import typer

from rich import box
from rich.columns import Columns
from rich.console import Console
from rich.prompt import IntPrompt
from rich.style import Style
from rich.table import Table
from rich.text import Text

DB_PATH = Path.home() / "Library/Containers/com.apple.Safari/Data/Library/Safari/SafariTabs.db"
# DB_PATH = Path.home() / "Downloads/SafariTabs.db"

SQL_QUERY = """
SELECT (SELECT title FROM bookmarks WHERE id = b.parent) AS TabGroup, title, url
FROM bookmarks b
WHERE parent IN (SELECT id FROM bookmarks WHERE type = 1)
  AND title != 'TopScopedBookmarkList'
  AND (SELECT title FROM bookmarks WHERE id = b.parent) != 'Root'
ORDER BY TabGroup, title
"""

type Tab = tuple[str, str, str]

out = Console(highlight=False)
err = Console(stderr=True)
app = typer.Typer(no_args_is_help=True, add_completion=False)


def load_tabs() -> list[Tab]:
    """Read every tab as (group, title, url) from the Safari database."""

    if not DB_PATH.is_file():
        err.print(f"Safari tabs database not found: {DB_PATH}", markup=False)
        raise typer.Exit(1)

    with sqlite3.connect(f"file:{DB_PATH}?mode=ro", uri=True) as db:
        return [(g or "", t or "", u or "") for g, t, u in db.execute(SQL_QUERY)]


def md_cell(s: str) -> str:
    return s.replace("\r", "").replace("\n", " ").replace("|", "&#124;")


def link(url: str, pattern: re.Pattern[str] | None = None) -> Text:
    """Render a URL as a clickable link with optional match highlights."""

    text = Text(url, style=Style(color="blue", link=url or None))

    if pattern:
        text.highlight_regex(pattern, "bold reverse")

    return text


def highlighted(s: str, pattern: re.Pattern[str] | None) -> Text:
    text = Text(s)

    if pattern:
        text.highlight_regex(pattern, "bold reverse")

    return text


def sorted_groups(tabs: Iterable[Tab]) -> list[str]:
    return sorted({g for g, _, _ in tabs if g}, key=str.casefold)


def show_tabs(tabs: Sequence[Tab], *, title: str | None = None, pattern: re.Pattern[str] | None = None) -> None:
    """Print tabs as a table grouped by tab group, or as pipe-delimited lines if stdout is not a terminal.

    Args:
        tabs: Tabs to print, ordered by group.
        title: Table title; if set, the group column is omitted.
        pattern: Regex whose matches are highlighted.
    """
    if not out.is_terminal:
        for g, t, u in tabs:
            print(f"{t}|{u}" if title else f"{g}|{t}|{u}")
        return

    table = Table(box=box.SIMPLE_HEAD, title=title, title_style="bold magenta", caption=f"{len(tabs)} tab{'s' if len(tabs) != 1 else ''}", expand=True)

    if not title:
        table.add_column("Group", style="bold cyan", no_wrap=True)

    table.add_column("Title", ratio=1, no_wrap=True, overflow="ellipsis")
    table.add_column("URL", ratio=1, no_wrap=True, overflow="ellipsis")

    by_group: dict[str, list[Tab]] = defaultdict(list)

    for tab in tabs:
        by_group[tab[0]].append(tab)

    for g, rows in by_group.items():
        for i, (_, t, u) in enumerate(rows):
            cells = [highlighted(t, pattern), link(u, pattern)]
            if not title:
                cells.insert(0, highlighted(g, pattern) if i == 0 else Text(""))
            table.add_row(*cells, end_section=i == len(rows) - 1)

    out.print(table)


def show_counts(groups: Iterable[str], *, by_count: bool) -> None:
    """Print the tab count per group, sorted by count or by group name."""

    counts = sorted(Counter(groups).items(), key=lambda kv: (kv[1], kv[0]) if by_count else kv[0].casefold())

    if not out.is_terminal:
        for group, n in counts:
            print(f"{n:3d} {group}")
        return

    table = Table(box=box.SIMPLE_HEAD, show_footer=True)
    table.add_column("Group", "Total", style="bold cyan", footer_style="bold")
    table.add_column("Tabs", str(sum(n for _, n in counts)), justify="right", style="green", footer_style="bold")

    for group, n in counts:
        table.add_row(group or "[dim](none)[/]", str(n))

    out.print(table)


def show_duplicates(tabs: Sequence[Tab]) -> None:
    """Print each URL that appears in more than one tab, with the groups that hold it."""

    seen: dict[str, list[str]] = defaultdict(list)

    for g, _, u in tabs:
        if u:
            seen[u].append(g)
    dupes = {u: gs for u, gs in sorted(seen.items()) if len(gs) > 1}

    if not out.is_terminal:
        print("\n".join(dupes))
        return

    if not dupes:
        out.print("[green]No duplicate URLs.[/]")
        return

    table = Table(box=box.SIMPLE_HEAD, caption=f"{len(dupes)} duplicate URL{'s' if len(dupes) != 1 else ''}", expand=True)
    table.add_column("URL", ratio=1, overflow="fold")
    table.add_column("Count", justify="right", style="yellow")
    table.add_column("Groups", style="cyan")

    for u, gs in dupes.items():
        table.add_row(link(u), str(len(gs)), ", ".join(sorted(set(gs), key=str.casefold)))

    out.print(table)


def show_groups(tabs: Sequence[Tab]) -> None:
    groups = sorted_groups(tabs)

    if out.is_terminal:
        out.print(Columns([Text(g, style="bold cyan") for g in groups], padding=(0, 4)))
    else:
        print("\n".join(groups))


def pick_group(tabs: Sequence[Tab]) -> str:
    """Prompt the user to choose a tab group from a numbered list."""
    groups = sorted_groups(tabs)

    if not groups:
        err.print("No tab groups found.")
        raise typer.Exit(1)

    counts = Counter(g for g, _, _ in tabs)

    for i, g in enumerate(groups, 1):
        err.print(f"[bold]{i:>3}[/]) [cyan]{g}[/] [dim]({counts[g]})[/]", highlight=False)

    choice = IntPrompt.ask(
        "Select a tab group",
        choices=[str(i) for i in range(1, len(groups) + 1)],
        show_choices=False,
        console=err,
    )

    return groups[choice - 1]


@app.command(help=__doc__, no_args_is_help=True)
def main(
    duplicates: Annotated[bool, typer.Option("-d", help="List duplicate tab URLs")] = False,
    count: Annotated[bool, typer.Option("-n", help="List the number of tabs in each tab group")] = False,
    grep: Annotated[str | None, typer.Option("-g", metavar="REGEX", help="Grep the tab listing with the provided regex")] = None,
    pipe: Annotated[bool, typer.Option("-l", help="List all tabs")] = False,
    table: Annotated[bool, typer.Option("-t", help="List all tabs as a Markdown table")] = False,
    as_csv: Annotated[bool, typer.Option("-c", help="List all tabs as CSV")] = False,
    groups: Annotated[bool, typer.Option("-L", help="List tab group names sorted alphabetically")] = False,
    select: Annotated[bool, typer.Option("-s", help="List tabs in GROUP; omit GROUP to pick interactively")] = False,
    group: Annotated[str | None, typer.Argument(metavar="[GROUP]", show_default=False)] = None,
) -> None:
    tabs = load_tabs()

    if grep is not None:
        try:
            pattern = re.compile(grep)
        except re.error as e:
            err.print(f"[red]Invalid regex:[/] {e}")
            raise typer.Exit(2) from e
        matches = [tab for tab in tabs if pattern.search("|".join(tab))]
        if count:
            show_counts((g for g, _, _ in matches), by_count=False)
        else:
            show_tabs(matches, pattern=pattern)
    elif duplicates:
        show_duplicates(tabs)
    elif count:
        show_counts((g for g, _, _ in tabs if g), by_count=True)
    elif pipe:
        show_tabs(tabs)
    elif table:
        print("| TabGroup | Title | URL |\n| --- | --- | --- |")
        for tab in tabs:
            print("| " + " | ".join(map(md_cell, tab)) + " |")
    elif as_csv:
        csv.writer(sys.stdout, quoting=csv.QUOTE_ALL, lineterminator="\n").writerows(tabs)
    elif groups:
        show_groups(tabs)
    elif select:
        name = group or pick_group(tabs)
        show_tabs([tab for tab in tabs if tab[0] == name], title=name)


if __name__ == "__main__":
    app()
