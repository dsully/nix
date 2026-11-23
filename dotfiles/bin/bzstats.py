#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.14"
# dependencies = ["rich", "typer"]
# ///
"""Report on Backblaze: live processes, daily upload churn, and history.

Backblaze writes one log per day of month (01.log ... 31.log) and zips the
previous ones, so 13.zip holds the 13th of last month or this month.
"""

import json
import re
import subprocess
import xml.etree.ElementTree as ET
import zipfile

from collections import Counter
from collections.abc import Sequence
from dataclasses import dataclass, field
from datetime import date, datetime, timedelta
from pathlib import Path, PurePath
from typing import Annotated, Self

import typer

from rich.console import Console, JustifyMethod
from rich.table import Table

BZDATA = Path("/Library/Backblaze.bzpkg/bzdata")
LOG_DIR = BZDATA / "bzlogs/bzreports_lastfilestransmitted"
STATUS = BZDATA / "overviewstatus.xml"
SAMPLES = Path.home() / ".local/share/bzmonitor/samples.jsonl"
PROCESSES = ("bzserv", "bztransmit", "bzfilelist")
HOME = str(Path.home())
BAR_WIDTH = 40

LINE_RE = re.compile(r"^(?P<day>\d{4}-\d\d-\d\d) (?P<hour>\d\d):\d\d:\d\d - ")
BYTES_RE = re.compile(r"([\d,]+) bytes - ")

# Leftmost " - /" starts the path, so paths may hold spaces, "@", or non-ASCII.
PATH_RE = re.compile(r" - (?:Chunk [0-9a-f]+ of )?(/.+)$")

console = Console(highlight=False, soft_wrap=True)
app = typer.Typer(add_completion=False, help=__doc__)


def human_bytes(n: float) -> str:
    for unit in ("B", "KB", "MB", "GB"):
        if n < 1024:
            return f"{n:.0f}{unit}" if unit == "B" else f"{n:.1f}{unit}"
        n /= 1024
    return f"{n:.1f}TB"


def bar(value: float, peak: float) -> str:
    return "█" * round(value / peak * BAR_WIDTH) if peak else ""


def tilde(path: PurePath | str) -> str:
    return str(path).replace(HOME, "~", 1)


def table(*columns: JustifyMethod) -> Table:
    grid = Table(box=None, show_header=False, pad_edge=False, padding=(0, 1))

    for justify in columns:
        grid.add_column(justify=justify)

    return grid


@dataclass
class DayLog:
    """One day of bzreports_lastfilestransmitted, read from a .log or .zip."""

    source: Path
    day: date | None = None
    uploads: int = 0
    dedups: int = 0
    bytes: int = 0
    hourly: Counter[int] = field(default_factory=Counter)
    folders: Counter[PurePath] = field(default_factory=Counter)

    @property
    def transmissions(self) -> int:
        return self.uploads + self.dedups

    @staticmethod
    def resolve(name: str | None) -> Path:
        """Map a log name (default: today's) to a path, relative names under LOG_DIR."""
        path = Path(name or f"{date.today().day:02d}.log")  # noqa: DTZ011 - logs use local wall-clock time

        return path if path.is_absolute() else LOG_DIR / path

    @staticmethod
    def recent(n: int) -> list[Path]:
        logs = [p for p in LOG_DIR.glob("[0-3][0-9].*") if p.suffix in {".log", ".zip"}]

        return sorted(logs, key=lambda p: p.stat().st_mtime)[-n:]

    @staticmethod
    def read(path: Path) -> str:
        if path.suffix == ".zip":
            with zipfile.ZipFile(path) as archive:
                return archive.read(archive.namelist()[0]).decode(errors="replace")

        return path.read_text(errors="replace")

    @classmethod
    def load(cls, path: Path) -> Self:
        log = cls(path)

        for line in cls.read(path).splitlines():
            if not (stamp := LINE_RE.match(line)):
                continue

            log.day = log.day or date.fromisoformat(stamp["day"])

            if size := BYTES_RE.search(line):
                log.bytes += int(size[1].replace(",", ""))

            # Batch headers carry bytes but no path; their files follow on their own lines.
            if not (file := PATH_RE.search(line)):
                continue

            log.hourly[int(stamp["hour"])] += 1

            if "dedup" in line[: file.start()]:
                log.dedups += 1
            else:
                log.uploads += 1

            log.folders[PurePath(file[1]).parent] += 1

        return log

    def top_folders(self, depth: int, top: int) -> list[tuple[PurePath, int]]:
        """Sum transmissions per folder, truncated to `depth` path parts."""

        truncated: Counter[PurePath] = Counter()

        for folder, count in self.folders.items():
            truncated[PurePath(*folder.parts[:depth])] += count

        return truncated.most_common(top)


@dataclass
class Process:
    """A running Backblaze process as reported by ps."""

    name: str
    cpu: float
    rss_kb: int
    elapsed: str

    @classmethod
    def running(cls) -> Sequence[Process]:

        out = subprocess.run(["ps", "-axo", "pcpu=,rss=,etime=,comm="], capture_output=True, text=True, check=True).stdout
        found = []

        for line in out.splitlines():
            cpu, rss, elapsed, command = line.split(None, 3)

            if (name := PurePath(command).name).startswith(PROCESSES):
                found.append(cls(name, float(cpu), int(rss), elapsed))

        return found

    @staticmethod
    def state() -> str | None:
        """Return bztransmit's cur_state from overviewstatus.xml."""

        try:
            node = ET.parse(STATUS).find("bztransmit")
        except OSError, ET.ParseError:
            return None

        return node.get("cur_state") if node is not None else None


@dataclass
class Sample:
    """One bztransmit CPU reading written by the bzmonitor sampler."""

    time: datetime
    cpu: float

    @classmethod
    def since(cls, cutoff: datetime) -> list[Self]:
        samples = []

        for line in SAMPLES.read_text().splitlines():
            try:
                record = json.loads(line)
                sample = cls(datetime.fromisoformat(record["t"]), float(record["tx"][0]))
            except ValueError, KeyError, IndexError, TypeError:
                continue

            if sample.time >= cutoff:
                samples.append(sample)

        return samples


@app.command()
def now() -> None:
    """Show running Backblaze processes and transmit state."""

    console.rule("now", align="left")
    grid = table("left", "right", "right", "right")

    for proc in Process.running():
        grid.add_row(proc.name, f"cpu {proc.cpu:.1f}%", f"mem {human_bytes(proc.rss_kb * 1024)}", f"up {proc.elapsed}")

    console.print(grid)

    if state := Process.state():
        console.print(f"state: [bold]{state}[/]")


@app.command()
def today() -> None:
    """Break down today's transmissions by kind, folder, and hour."""

    path = DayLog.resolve(None)
    console.rule(f"today ({path.name})", align="left")

    if not path.exists():
        console.print("no log yet")
        return

    log = DayLog.load(path)
    console.print(f"transmissions: {log.transmissions:,}  (uploads {log.uploads:,} · dedup re-checks {log.dedups:,})")
    console.print(f"bytes moved:   {human_bytes(log.bytes)}")
    console.print("top folders:")
    folders = table("right", "left")

    for folder, count in log.top_folders(depth=5, top=6):
        folders.add_row(f"  {count:,}", tilde(folder))

    console.print(folders)
    console.print("by hour:")
    hours = table("right", "left", "right")
    peak = max(log.hourly.values(), default=0)

    for hour in range(datetime.now().hour + 1):  # noqa: DTZ005
        hours.add_row(f"  {hour:02d}", f"[cyan]{bar(log.hourly[hour], peak)}[/]", f"{log.hourly[hour]:,}")

    console.print(hours)


@app.command()
def days(count: Annotated[int, typer.Option("--count", "-n", help="number of days")] = 8) -> None:
    """Compare transmissions and bytes over recent days."""
    console.rule("recent days", align="left")
    logs = sorted((DayLog.load(p) for p in DayLog.recent(count)), key=lambda log: log.day or date.min)
    peak = max((log.transmissions for log in logs), default=0)
    grid = table("left", "left", "right", "right")

    for log in logs:
        label = log.day.strftime("%b %d") if log.day else log.source.name
        grid.add_row(label, f"[cyan]{bar(log.transmissions, peak)}[/]", f"{log.transmissions:,}", f"({human_bytes(log.bytes)})")

    console.print(grid)


@app.command()
def cpu() -> None:
    """Summarize sampled bztransmit CPU over the last 24 hours."""

    console.rule("bztransmit CPU (sampled)", align="left")

    if not SAMPLES.exists():
        console.print("no samples yet (the bzmonitor sampler writes them over time)")
        return

    samples = Sample.since(datetime.now() - timedelta(hours=24))  # noqa: DTZ005 - samples are naive local time

    if not samples:
        console.print("no samples in the last 24h")
        return

    cpus = [s.cpu for s in samples]
    busiest = max(samples, key=lambda s: s.cpu)

    console.print(
        f"last 24h: {len(samples)} samples · avg {sum(cpus) / len(cpus):.0f}% · "
        f"max {busiest.cpu:.0f}% at {busiest.time:%H:%M} · {sum(c > 50 for c in cpus)} samples >50%"
    )

    by_hour: dict[int, list[float]] = {}

    for s in samples:
        by_hour.setdefault(s.time.hour, []).append(s.cpu)

    averages = {hour: sum(v) / len(v) for hour, v in sorted(by_hour.items())}
    peak = max(averages.values())
    grid = table("right", "left", "right")

    for hour, avg in averages.items():
        grid.add_row(f"  {hour:02d}", f"[cyan]{bar(avg, peak)}[/]", f"{avg:.0f}% avg")

    console.print(grid)


@app.command()
def churn(
    log: Annotated[str | None, typer.Argument(help="log file, e.g. 13.log or 13.zip (default: today's)")] = None,
    depth: Annotated[int, typer.Option("--depth", "-d", help="truncate folders to this many path parts")] = 6,
    top: Annotated[int, typer.Option("--top", "-n", help="number of folders to show")] = 20,
) -> None:
    """Rank the folders Backblaze re-uploads most, to find caches worth excluding."""
    path = DayLog.resolve(log)

    if not path.exists():
        console.print(f"[red]log not found:[/] {path}")
        raise typer.Exit(1)

    day = DayLog.load(path)

    if not day.transmissions:
        console.print(f"[red]no file paths found in[/] {path}")
        raise typer.Exit(1)

    console.print(f"log: {path}  ({day.transmissions:,} transmissions)")
    console.print(f"top folders, truncated to depth {depth}:\n")

    grid = table("right", "left")

    for folder, count in day.top_folders(depth, top):
        grid.add_row(f"{count:,}", tilde(folder))

    console.print(grid)


@app.callback(invoke_without_command=True)
def report(ctx: typer.Context) -> None:
    """Without a subcommand, print now, today, days, and cpu in turn."""

    if ctx.invoked_subcommand is not None:
        return

    for section in (now, today, days, cpu):
        section()
        console.print()


if __name__ == "__main__":
    app()
