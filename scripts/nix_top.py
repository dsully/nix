#!/usr/bin/env python3
"""Show the largest Nix store paths, what keeps them alive, and what refers to them."""

import json
import re
import subprocess

from collections import Counter, defaultdict
from collections.abc import Callable, Iterable, Mapping, Sequence
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass
from itertools import groupby
from pathlib import Path
from typing import Annotated, Any

import typer

from rich.console import Console
from rich.table import Table
from rich.text import Text

STORE = "/nix/store/"
MAX_LABELS = 3
DEFAULT_ROOTS = ("/run/current-system", str(Path.home() / ".local/state/nix/profiles/home-manager"))
HASHED = re.compile(r"/nix/store/[0-9a-z]{32}-")
GENERATION = re.compile(r"^(?P<profile>.+)-\d+-link$")
PROCESS = re.compile(r"(?:\{libproc|^/proc)/(\d+)/")
PROFILE_NAMES = {"current-home": "home", "current-system": "system", "home-manager": "home", "system-manager": "system", "system-manager-current": "system"}
# system-manager keeps no unnumbered profile link; this gcroot marks its current generation instead.
CURRENT_LINKS = {"system-manager": Path("/nix/var/nix/gcroots/system-manager-current")}
SYSTEM_PROFILE = "/nix/var/nix/profiles/" + ("system-manager-profiles/system-manager" if CURRENT_LINKS["system-manager"].exists() else "system")
DEAD = "dead"
PROCESSES = "processes"
ACTIONS = {
    DEAD: "nix-collect-garbage",
    "old system": f"sudo $(command -v nh) clean profile {SYSTEM_PROFILE}",  # sudo's secure_path drops the user profile holding nh
    "old home": "nh clean profile ~/.local/state/nix/profiles/home-manager",
    "old profile": "nh clean profile ~/.local/state/nix/profiles/profile",
}

type Json = Mapping[str, Any]  # untyped objects from `nix path-info --json`

console = Console(highlight=False)
err = Console(stderr=True)
app = typer.Typer(add_completion=False)


@dataclass(frozen=True)
class PathInfo:
    path: str
    nar_size: int
    closure_size: int | None
    references: tuple[str, ...]
    deriver: str | None = None


@dataclass(frozen=True)
class Row:
    size: int
    members: tuple[str, ...]
    grouped: bool


@dataclass(frozen=True)
class GcState:
    roots: dict[str, set[str]]
    dead: set[str]


def split_name(path: str) -> tuple[str, str]:
    """Split a store path into package name and the version/output suffix, dropping the hash."""
    name = path.removeprefix(STORE).partition("-")[2]
    package = re.sub(r"-[^a-zA-Z].*$", "", name.removesuffix(".drv"))

    return package, name[len(package) :].lstrip("-")


def pname(path: str) -> str:
    """Return the package name of a store path, without hash, version or `.drv`."""
    return split_name(path)[0]


def version(path: str) -> str:
    return split_name(path)[1].removesuffix(".drv").partition("-")[0]


def human(size: int) -> str:
    value = float(size)

    for unit in ("B", "KiB", "MiB", "GiB"):
        if value < 1024:
            return f"{value:.1f} {unit}"
        value /= 1024

    return f"{value:.1f} TiB"


def parse(data: Sequence[Json] | Mapping[str, Json | None]) -> list[PathInfo]:
    """Normalize `nix path-info --json` output; Lix/older Nix emit a list, newer Nix an object keyed by path."""
    pairs = [(e["path"], e) for e in data] if isinstance(data, Sequence) else [(p, e) for p, e in data.items() if e]

    return [
        PathInfo(
            path=path,
            nar_size=e["narSize"],
            closure_size=e.get("closureSize"),
            references=tuple(e.get("references") or ()),
            deriver=e.get("deriver"),
        )
        for path, e in pairs
    ]


def root_label(link: str, processes: Mapping[str, str]) -> str:
    """Name the GC root `link` by what it is: a current or old profile generation, a process, a dev shell, or a path."""
    if m := PROCESS.search(link):
        return f"process {processes.get(m[1], 'exited')} {m[1]}"

    if link.startswith("{"):
        return "process censored ?"

    path = Path(link)

    if ".direnv" in path.parts:
        return f"direnv {path.parts[path.parts.index('.direnv') - 1]}"
    if m := GENERATION.match(link):
        profile = Path(m["profile"])
        name = PROFILE_NAMES.get(profile.name, profile.name)
        pointer = CURRENT_LINKS.get(profile.name, profile)
        current = pointer.is_symlink() and pointer.resolve() == path.resolve()

        return name if current else f"old {name}"

    if path.name in PROFILE_NAMES:
        return PROFILE_NAMES[path.name]

    return link.replace(str(Path.home()), "~", 1)


def kept_by(infos: Iterable[PathInfo], gc: GcState) -> dict[str, set[str]]:
    """Map each path to the labels of GC roots whose closure holds it, or to `dead`."""
    # shortcut: follows derivers as if keep-derivations = true and keep-outputs = false (the defaults); read `nix config show` if they change.
    edges = {i.path: (*i.references, *((i.deriver,) if i.deriver else ())) for i in infos}
    labels: defaultdict[str, set[str]] = defaultdict(set)

    for label, targets in gc.roots.items():
        seen: set[str] = set()
        stack = [t for t in targets if t in edges]

        while stack:
            if (path := stack.pop()) in seen:
                continue
            seen.add(path)
            labels[path].add(label)
            stack.extend(p for p in edges[path] if p in edges and p not in seen)

    for path in gc.dead:
        labels[path] = {DEAD}

    return labels


def top_rows(infos: Iterable[PathInfo], count: int, *, closure: bool = False, group: bool = False) -> list[Row]:
    """Return the `count` largest paths, or package names when `group` sums NAR size across versions."""
    if group:
        by_name = groupby(sorted(infos, key=lambda i: pname(i.path)), key=lambda i: pname(i.path))
        rows = [Row(size=sum(i.nar_size for i in members), members=tuple(i.path for i in members), grouped=True) for members in (list(g) for _, g in by_name)]
    else:
        rows = [Row(size=size, members=(i.path,), grouped=False) for i in infos if (size := i.closure_size if closure else i.nar_size) is not None]

    return sorted(rows, key=lambda r: -r.size)[:count]


def referrers(infos: Iterable[PathInfo], rows: Iterable[Row]) -> dict[Row, list[str]]:
    """Map each row to the sorted package names of paths that directly reference one of its members."""
    rows = list(rows)
    wanted = {m for r in rows for m in r.members}
    by_ref: defaultdict[str, set[str]] = defaultdict(set)

    for info in infos:
        for ref in info.references:
            if ref in wanted and ref != info.path:
                by_ref[ref].add(info.path)

    return {r: sorted({pname(p) for m in r.members for p in by_ref[m] if p not in r.members}) for r in rows}


def label(row: Row, versions: Mapping[str, set[str]], *, paths: bool) -> Text:
    package = pname(row.members[0])

    if row.grouped:
        return Text.assemble((package, "bold"), (f"  {len(row.members)} paths", "dim"))

    path = row.members[0]

    if paths:
        digest, _, name = path.removeprefix(STORE).partition("-")
        return Text.assemble((f"{STORE}{digest}-", "dim"), (name, "bold"))

    others = len(versions[package] - {""})

    return Text.assemble((package, "bold"), " ", (split_name(path)[1], "dim"), (f"  {others} versions" if others > 1 else "", "magenta"))


def label_rank(name: str) -> tuple[int, str]:
    rank = 5 if is_process(name) else 4 if name.startswith("old ") else 3

    return ({DEAD: 0, "system": 1, "home": 2}.get(name, rank), name)


def is_process(name: str) -> bool:
    return name == PROCESSES or name.startswith("process ")


def collapse(label: str) -> str:
    """Drop the PID from a process label so one name stands for all its processes."""
    return label.rpartition(" ")[0] if label.startswith("process ") else label


def render_label(name: str) -> Text:
    if is_process(name):
        return Text(name.removeprefix("process "), style="blue")

    return Text(name, style={DEAD: "red", "system": "green", "home": "green"}.get(name, "yellow" if name.startswith("old ") else ""))


def capped(names: Sequence[str], render: Callable[[str], Text] = Text, limit: int | None = MAX_LABELS) -> Text:
    if not names:
        return Text("—", style="dim")

    text = Text(", ").join(render(n) for n in names[:limit])

    if limit and (extra := len(names) - limit) > 0:
        text.append(f" +{extra}", style="dim")

    return text


def run(cmd: Sequence[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(cmd, capture_output=True, text=True, check=False)


def path_info(roots: Sequence[str], *, closure: bool) -> list[PathInfo]:
    result = run(["nix", "path-info", "--json", *(["-S"] if closure else []), *(["-r", *roots] if roots else ["--all"])])

    if result.returncode != 0:
        err.print(result.stderr.strip(), markup=False)
        raise typer.Exit(result.returncode)

    return parse(json.loads(result.stdout))


def process_names(pids: Iterable[str]) -> dict[str, str]:
    if not (pids := sorted(set(pids))):
        return {}

    lines = run(["ps", "-o", "pid=,comm=", "-p", ",".join(pids)]).stdout.splitlines()

    return {pid: Path(comm.strip()).name.lstrip("-").partition(":")[0] for pid, _, comm in (line.strip().partition(" ") for line in lines)}


def gc_state() -> GcState | None:
    """Query GC roots and dead paths; None (with a warning) when the store refuses, e.g. without daemon access."""
    roots, dead = run(["nix-store", "--gc", "--print-roots"]), run(["nix-store", "--gc", "--print-dead"])

    if roots.returncode or dead.returncode:
        err.print(f"[yellow]Skipping 'kept by':[/yellow] {(roots.stderr or dead.stderr).strip()}")
        return None

    processes = process_names(PROCESS.findall(roots.stdout))
    by_label: defaultdict[str, set[str]] = defaultdict(set)

    for line in roots.stdout.splitlines():
        link, sep, target = line.rpartition(" -> ")
        if sep:
            by_label[root_label(link, processes)].add(target)

    return GcState(roots=dict(by_label), dead=set(dead.stdout.split()))


def reclaimable(infos: Iterable[PathInfo], keepers: Mapping[str, set[str]]) -> tuple[dict[str, int], list[str]]:
    """Return, per action, the NAR size of paths only that action frees, plus the processes holding process-only paths, largest first."""
    freed = dict.fromkeys([*ACTIONS, PROCESSES], 0)
    holders: Counter[str] = Counter()

    for info in infos:
        kept = keepers.get(info.path, set())

        if kept and all(is_process(k) for k in kept):
            freed[PROCESSES] += info.nar_size
            holders.update(dict.fromkeys(kept, info.nar_size))
        elif len(kept) == 1 and (only := next(iter(kept))) in freed:
            freed[only] += info.nar_size

    return {k: v for k, v in freed.items() if v}, [name for name, _ in holders.most_common()]


def actions(freed: Mapping[str, int], holders: Sequence[str]) -> Table:
    grid = Table.grid(padding=(0, 2))
    grid.add_column(justify="right", style="cyan")
    grid.add_column()
    grid.add_column(style="bold")

    for name, size in freed.items():
        holding = capped(list(dict.fromkeys(map(collapse, holders))), render_label)
        command = Text.assemble("quit or restart ", holding, ", then nix-collect-garbage") if name == PROCESSES else ACTIONS[name]
        grid.add_row(human(size), render_label(name), command)

    return grid


def process_table(infos: Iterable[PathInfo], keepers: Mapping[str, set[str]]) -> Table:
    """Per process name: NAR size of paths held only by running processes, and the PIDs holding them."""
    sizes: Counter[str] = Counter()
    pids: defaultdict[str, set[str]] = defaultdict(set)

    for info in infos:
        if (kept := keepers.get(info.path, set())) and all(is_process(k) for k in kept):
            names = set()

            for k in kept:
                name, _, pid = k.removeprefix("process ").rpartition(" ")
                names.add(name)
                pids[name].add(pid)

            sizes.update(dict.fromkeys(names, info.nar_size))

    table = Table(box=None, padding=(0, 2))
    table.add_column("held", justify="right", style="cyan", no_wrap=True)
    table.add_column("process", style="blue", no_wrap=True)
    table.add_column("count", justify="right", no_wrap=True)
    table.add_column("pids", style="dim")

    for name, size in sizes.most_common():
        table.add_row(human(size), name, str(len(pids[name])), " ".join(sorted(pids[name], key=lambda p: (len(p), p))))

    return table


def legend() -> Text:
    samples = (
        (DEAD, "no GC root"),
        ("system", "current generation"),
        ("old home", "older generation"),
        ("process <name>", "running process"),
        ("~/link", "other GC root"),
    )

    return Text.assemble(("kept by  ", "dim"), Text("  ·  ", style="dim").join(Text.assemble(render_label(n), (f" {d}", "dim")) for n, d in samples))


def strip_hashes(text: str) -> str:
    return HASHED.sub("", text)


def why(name: str, roots: Sequence[str]) -> None:
    """Print the reverse-dependency tree from each root to every path named `name` in its closure."""
    roots = roots or [r for r in DEFAULT_ROOTS if Path(r).exists()]
    found = False

    for root in roots:
        with console.status(f"Querying {root}…"):
            targets = [i.path for i in path_info([root], closure=False) if name in (i.path, pname(i.path))]

        for target in targets:
            found = True
            result = run(["nix", "why-depends", "--all", root, target])
            console.rule(Text.assemble((root, "bold"), " → ", (strip_hashes(target), "bold yellow")))
            console.print(Text.from_ansi(strip_hashes(result.stdout or result.stderr)))

    if not found:
        err.print(f"{name} is not in the closure of {', '.join(roots)}", markup=False)
        raise typer.Exit(1)


def summary(infos: Sequence[PathInfo], scope: str, gc: GcState | None) -> Text:
    text = Text.assemble((scope, "bold"), f"  {human(sum(i.nar_size for i in infos))} · {len(infos):,} paths")

    if gc:
        dead = [i for i in infos if i.path in gc.dead]
        text.append(f" · {human(sum(i.nar_size for i in dead))} dead ({len(dead):,} paths)", style="red")

    return text


@app.command()
def main(
    roots: Annotated[list[str] | None, typer.Argument(help="Limit to the closure of these paths (default: whole store).")] = None,
    count: Annotated[int, typer.Option("-n", "--count", min=1, help="Rows to show.")] = 20,
    closure: Annotated[bool, typer.Option("-c", "--closure", help="Rank by closure size instead of own NAR size.")] = False,
    group: Annotated[bool, typer.Option("-g", "--group", help="Sum NAR size per package name across versions.")] = False,
    paths: Annotated[bool, typer.Option("-p", "--paths", help="Show full store paths instead of name and version.")] = False,
    verbose: Annotated[bool, typer.Option("-v", "--verbose", help="List every root, referrer and process (with PIDs) instead of the first few.")] = False,
    why_name: Annotated[
        str | None,
        typer.Option("-w", "--why", metavar="NAME", help="Show why NAME (package name or store path) is in each ROOT's closure."),
    ] = None,
) -> None:
    """List the largest Nix store paths with the GC roots keeping them ('kept by', whole store only) and their direct referrers."""
    if why_name:
        why(why_name, roots or [])
        return

    if closure and group:
        err.print("--closure and --group cannot be combined")
        raise typer.Exit(1)

    with console.status("Querying the Nix store…"), ThreadPoolExecutor() as pool:
        gc_future = None if roots else pool.submit(gc_state)
        infos = path_info(roots or [], closure=closure)
        gc = gc_future.result() if gc_future else None

    limit = None if verbose else MAX_LABELS
    rows = top_rows(infos, count, closure=closure, group=group)
    names = referrers(infos, rows)
    keepers = kept_by(infos, gc) if gc else {}
    versions: defaultdict[str, set[str]] = defaultdict(set)

    for info in infos:
        if not info.path.endswith(".drv"):
            versions[pname(info.path)].add(version(info.path))

    table = Table(title=summary(infos, " ".join(roots) if roots else "Nix store", gc), title_justify="left")
    table.add_column("closure" if closure else "size", justify="right", style="cyan", no_wrap=True)
    table.add_column("package" if group or not paths else "path", no_wrap=True)

    if gc:
        table.add_column("kept by")

    table.add_column("used by")

    for row in rows:
        kept = sorted({k if verbose else collapse(k) for m in row.members for k in keepers.get(m, {"other"})}, key=label_rank)
        kept_cell = [capped(kept, render_label, limit)] if gc else []
        cells = [human(row.size), label(row, versions, paths=paths), *kept_cell, capped(names[row], limit=limit)]
        table.add_row(*cells)

    console.print(table)

    if gc:
        console.print(legend())

    freed, holders = reclaimable(infos, keepers)

    if freed:
        console.print(Text("\nFree space", style="bold"))
        console.print(actions(freed, holders))

    if verbose and holders:
        console.print(Text("\nProcesses holding store paths nothing else keeps", style="bold"))
        console.print(process_table(infos, keepers))


if __name__ == "__main__":
    app()
