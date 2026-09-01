#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.14"
# dependencies = ["vulture>=2.16", "rich", "typer"]
# ///
"""Dead code analysis.

Run Vulture to find unused code, then enrich each finding with evidence from a
single AST pass over the source tree. The evidence drives a verdict and a
recommendation, so a reviewer can tell a safe deletion from a framework hook or
a dynamic reference.

The tool aims to keep the "needs review" bucket small. It reaches that goal with
whole-program reachability, class-hierarchy and Protocol awareness, entry-point
detection, dynamic-surface detection, and suppression support, so most findings
become a definite REMOVE or KEEP. The residue is genuinely dynamic code, which
static analysis cannot resolve without runtime data.
"""

import ast
import re
import subprocess
import tomllib

from collections import Counter, defaultdict, deque
from dataclasses import dataclass, field
from enum import StrEnum
from pathlib import Path
from typing import Annotated

import typer

from rich.console import Console
from rich.panel import Panel
from rich.syntax import Syntax
from rich.table import Table
from rich.text import Text
from vulture import Vulture

# Parameter names that callbacks and framework hooks require by convention.
CONVENTION_PARAMS = frozenset({"frame", "event", "context", "request", "response", "args", "kwargs", "self", "cls", "_"})

# Decorators that do not imply framework registration.
BENIGN_DECORATORS = frozenset(
    {
        "staticmethod",
        "classmethod",
        "property",
        "cached_property",
        "cache",
        "lru_cache",
        "wraps",
        "contextmanager",
        "asynccontextmanager",
        "singledispatch",
        "singledispatchmethod",
        "dataclass",
        "final",
        "total_ordering",
        "runtime_checkable",
    }
)

# Decorators that mark an interface contract; the symbol must keep its signature.
CONTRACT_DECORATORS = frozenset({"abstractmethod", "abstractproperty", "override", "overload"})

# Base classes that mark a class as an interface, so its methods are a contract.
CONTRACT_BASES = frozenset({"Protocol", "ABC", "ABCMeta"})

# Calls that expose a dynamic surface where static reachability is unreliable.
DYNAMIC_CALLS = frozenset({"getattr", "hasattr", "setattr", "globals", "vars", "__import__", "import_module"})

# Names that hint at a required interface when they head a symbol.
INTERFACE_PREFIX_RE = re.compile(r"^(callback|handler|listener|observer|_)")

# Comment markers that suppress a finding on that line.
NOQA_RE = re.compile(r"#\s*(noqa|vulture:\s*ignore)", re.IGNORECASE)

console = Console()


class Verdict(StrEnum):
    UNUSED = "UNUSED"
    DYNAMIC_USAGE = "DYNAMIC_USAGE"
    FRAMEWORK_CODE = "FRAMEWORK_CODE"
    PUBLIC_API = "PUBLIC_API"
    TEST_ONLY = "TEST_ONLY"
    DEAD_CHAIN = "DEAD_CHAIN"
    IN_USE = "IN_USE"


class Risk(StrEnum):
    LOW = "LOW"
    MEDIUM = "MEDIUM"
    HIGH = "HIGH"


class Category(StrEnum):
    REMOVE = "REMOVE"
    REMOVE_CHAIN = "REMOVE_CHAIN"
    TEST_ONLY = "TEST_ONLY"
    REVIEW = "REVIEW"
    KEEP = "KEEP"
    FALSE_POSITIVE = "FALSE_POSITIVE"


@dataclass(frozen=True)
class UnusedItem:
    """A single finding reported by Vulture."""

    name: str
    filename: Path
    lineno: int
    typ: str
    confidence: int


@dataclass(frozen=True)
class Definition:
    """A function or class definition and its decorators."""

    file: Path
    lineno: int
    kind: str
    decorators: tuple[str, ...]


@dataclass
class ProjectIndex:
    """Evidence collected from one AST pass over the source tree."""

    dead_files: set[Path] = field(default_factory=set)
    # name -> list of (file, is_test) for every read reference (Name/Attribute load).
    reads: dict[str, list[tuple[Path, bool]]] = field(default_factory=lambda: defaultdict(list))
    # name -> definitions of a function or class with that name.
    definitions: dict[str, list[Definition]] = field(default_factory=lambda: defaultdict(list))
    # parameter name -> functions that declare it.
    params: dict[str, list[Definition]] = field(default_factory=lambda: defaultdict(list))
    # class name -> base class name tails.
    class_bases: dict[str, set[str]] = field(default_factory=lambda: defaultdict(set))
    # class name -> method names defined directly in the class body.
    methods: dict[str, set[str]] = field(default_factory=lambda: defaultdict(set))
    # file -> (lineno, class name) for every class, to find a symbol's owning class.
    class_defs: dict[Path, list[tuple[int, str]]] = field(default_factory=lambda: defaultdict(list))
    # call graph: enclosing top-level symbol -> names it references.
    edges: dict[str, set[str]] = field(default_factory=lambda: defaultdict(set))
    # names referenced at module top level in production and test files.
    roots: set[str] = field(default_factory=set)
    test_roots: set[str] = field(default_factory=set)
    all_exports: set[str] = field(default_factory=set)
    entry_points: set[str] = field(default_factory=set)
    decorator_uses: Counter[str] = field(default_factory=Counter)
    string_refs: Counter[str] = field(default_factory=Counter)
    dynamic_refs: set[str] = field(default_factory=set)
    dynamic_modules: set[Path] = field(default_factory=set)
    noqa: dict[Path, set[int]] = field(default_factory=lambda: defaultdict(set))
    project_classes: set[str] = field(default_factory=set)
    reachable: set[str] = field(default_factory=set)


@dataclass
class Evidence:
    """Per-symbol facts used to reach a verdict."""

    is_parameter: bool = False
    string_uses: int = 0
    decorator_uses: int = 0
    own_decorators: tuple[str, ...] = ()
    framework_decorated: bool = False
    contract_decorated: bool = False
    in_all: bool = False
    in_init: bool = False
    is_dunder: bool = False
    reachable: bool = False
    overrides_contract: bool = False
    dynamic: bool = False
    in_dynamic_module: bool = False
    prod_refs: int = 0
    test_refs: int = 0
    reasons: list[str] = field(default_factory=list)


@dataclass(frozen=True)
class Outcome:
    verdict: Verdict
    risk: Risk
    category: Category
    recommendation: str
    style: str


CATEGORY_LABELS: dict[Category, tuple[str, str]] = {
    Category.REMOVE: ("SAFE TO REMOVE", "green"),
    Category.REMOVE_CHAIN: ("REMOVE AS DEAD CODE CHAIN", "green"),
    Category.TEST_ONLY: ("TEST-ONLY CODE", "yellow"),
    Category.REVIEW: ("NEEDS MANUAL REVIEW (dynamic surface)", "yellow"),
    Category.KEEP: ("DO NOT REMOVE", "red"),
    Category.FALSE_POSITIVE: ("DO NOT REMOVE - FALSE POSITIVE", "red"),
}


# --------------------------------------------------------------------------- #
# AST indexing
# --------------------------------------------------------------------------- #


def _dotted_name(node: ast.expr) -> str | None:
    """Return the dotted path of an expression, e.g. ``app.route``."""
    match node:
        case ast.Name():
            return node.id
        case ast.Attribute():
            base = _dotted_name(node.value)
            return f"{base}.{node.attr}" if base else node.attr
        case ast.Call():
            return _dotted_name(node.func)
        case _:
            return None


def _arg_names(func: ast.FunctionDef | ast.AsyncFunctionDef) -> list[str]:
    a = func.args
    names = [p.arg for p in (*a.posonlyargs, *a.args, *a.kwonlyargs)]
    if a.vararg:
        names.append(a.vararg.arg)
    if a.kwarg:
        names.append(a.kwarg.arg)
    return names


def _framework_decorated(decorators: tuple[str, ...]) -> bool:
    """True if a decorator implies framework registration (not a benign helper)."""
    return any(d.rsplit(".", 1)[-1] not in BENIGN_DECORATORS | CONTRACT_DECORATORS for d in decorators)


class _IndexVisitor(ast.NodeVisitor):
    """Fill a ProjectIndex from one module."""

    def __init__(self, index: ProjectIndex, file: Path, is_test: bool) -> None:
        self.index = index
        self.file = file
        self.is_test = is_test
        self.scope: list[str] = []
        self.dynamic = False

    def _record_ref(self, name: str) -> None:
        self.index.reads[name].append((self.file, self.is_test))
        if self.scope:
            self.index.edges[self.scope[0]].add(name)
        elif self.is_test:
            self.index.test_roots.add(name)
        else:
            self.index.roots.add(name)

    def _visit_def(self, node: ast.FunctionDef | ast.AsyncFunctionDef | ast.ClassDef) -> None:
        decorators = tuple(d for dec in node.decorator_list if (d := _dotted_name(dec)) is not None)
        kind = "class" if isinstance(node, ast.ClassDef) else "function"
        defn = Definition(file=self.file, lineno=node.lineno, kind=kind, decorators=decorators)
        self.index.definitions[node.name].append(defn)

        for dec in decorators:
            self.index.decorator_uses[dec.rsplit(".", 1)[-1]] += 1

        # A registration decorator makes the symbol a reachability root.
        if _framework_decorated(decorators):
            (self.index.test_roots if self.is_test else self.index.roots).add(node.name)

        if isinstance(node, ast.ClassDef):
            self.index.class_defs[self.file].append((node.lineno, node.name))
            self.index.class_bases[node.name] |= {b.rsplit(".", 1)[-1] for base in node.bases if (b := _dotted_name(base))}
            self.index.methods[node.name] |= {n.name for n in node.body if isinstance(n, ast.FunctionDef | ast.AsyncFunctionDef)}
        else:
            for arg in _arg_names(node):
                self.index.params[arg].append(defn)
            if node.name == "__getattr__" and not self.scope:
                self.dynamic = True

        self.scope.append(node.name)
        self.generic_visit(node)
        self.scope.pop()

    visit_FunctionDef = _visit_def
    visit_AsyncFunctionDef = _visit_def
    visit_ClassDef = _visit_def

    def visit_Name(self, node: ast.Name) -> None:
        if isinstance(node.ctx, ast.Load):
            self._record_ref(node.id)
        self.generic_visit(node)

    def visit_Attribute(self, node: ast.Attribute) -> None:
        if isinstance(node.ctx, ast.Load):
            self._record_ref(node.attr)
        self.generic_visit(node)

    def visit_Constant(self, node: ast.Constant) -> None:
        if isinstance(node.value, str):
            # Record the exact value and, for a dotted path, its final component,
            # so both `getattr(o, "name")` and `@patch("pkg.mod.name")` match.
            tail = node.value.rsplit(".", 1)[-1]
            for token in {node.value, tail}:
                self.index.string_refs[token] += 1

    def visit_Call(self, node: ast.Call) -> None:
        tail = (name := _dotted_name(node.func)) and name.rsplit(".", 1)[-1]
        if tail in ("getattr", "hasattr", "setattr"):
            if len(node.args) >= 2 and isinstance(node.args[1], ast.Constant) and isinstance(node.args[1].value, str):
                self.index.dynamic_refs.add(node.args[1].value)
            else:
                self.dynamic = True
        elif tail in DYNAMIC_CALLS:
            self.dynamic = True
        self.generic_visit(node)


def _collect_all_exports(tree: ast.Module, index: ProjectIndex) -> None:
    """Add names listed in a module-level ``__all__`` assignment."""
    for node in tree.body:
        if not isinstance(node, ast.Assign):
            continue
        if not any(isinstance(t, ast.Name) and t.id == "__all__" for t in node.targets):
            continue
        if isinstance(node.value, ast.List | ast.Tuple):
            index.all_exports.update(elt.value for elt in node.value.elts if isinstance(elt, ast.Constant) and isinstance(elt.value, str))


def build_index(files: list[Path], test_re: re.Pattern[str], dead_files: set[Path]) -> ProjectIndex:
    index = ProjectIndex(dead_files=dead_files)

    for file in files:
        try:
            text = file.read_text(encoding="utf-8")
            tree = ast.parse(text, filename=str(file))
        except SyntaxError, UnicodeDecodeError, OSError:
            continue

        index.noqa[file] = {i for i, line in enumerate(text.splitlines(), start=1) if NOQA_RE.search(line)}

        is_test = bool(test_re.search(file.as_posix()))
        visitor = _IndexVisitor(index, file, is_test)
        visitor.visit(tree)
        if visitor.dynamic:
            index.dynamic_modules.add(file)

        _collect_all_exports(tree, index)

    index.project_classes = {name for name, defs in index.definitions.items() if any(d.kind == "class" for d in defs)}
    return index


def _reachability(index: ProjectIndex) -> set[str]:
    """Return every symbol reachable from a production root via the call graph."""
    reachable: set[str] = set()
    queue = deque(index.roots | index.all_exports | index.entry_points)
    while queue:
        name = queue.popleft()
        if name in reachable:
            continue
        reachable.add(name)
        queue.extend(index.edges.get(name, ()))
    return reachable


def load_entry_points(roots: set[Path]) -> set[str]:
    """Return function names declared as entry points in each repo's pyproject."""
    names: set[str] = set()
    for root in roots:
        pyproject = root / "pyproject.toml"
        if not pyproject.is_file():
            continue
        try:
            data = tomllib.loads(pyproject.read_text(encoding="utf-8"))
        except tomllib.TOMLDecodeError, OSError:
            continue

        project = data.get("project", {})
        for key in ("scripts", "gui-scripts"):
            names.update(_entry_func(v) for v in project.get(key, {}).values())
        for group in project.get("entry-points", {}).values():
            if isinstance(group, dict):
                names.update(_entry_func(v) for v in group.values())

    names.discard("")
    return names


def _entry_func(value: str) -> str:
    """Extract the callable name from a ``module.path:func [extra]`` entry point."""
    right = value.split(":", 1)[1] if ":" in value else value
    return right.split("[", 1)[0].strip()


# --------------------------------------------------------------------------- #
# Evidence and verdict
# --------------------------------------------------------------------------- #


def _declaring_funcs(item: UnusedItem, index: ProjectIndex) -> list[Definition]:
    """Functions in the same file that declare a parameter with this name."""
    return [d for d in index.params.get(item.name, ()) if d.file == item.filename and abs(d.lineno - item.lineno) <= 5]


def _own_decorators(item: UnusedItem, index: ProjectIndex) -> tuple[str, ...]:
    for defn in index.definitions.get(item.name, ()):
        if defn.file == item.filename and abs(defn.lineno - item.lineno) <= 1:
            return defn.decorators
    return ()


def _owning_class(item: UnusedItem, index: ProjectIndex) -> str | None:
    """Return the class that lexically contains ``item`` (nearest class above)."""
    candidates = [(line, name) for line, name in index.class_defs.get(item.filename, ()) if line <= item.lineno]
    return max(candidates)[1] if candidates else None


def _ancestors(cls: str, index: ProjectIndex) -> set[str]:
    """Return all transitive base names of ``cls`` (project and external)."""
    seen: set[str] = set()
    queue = deque(index.class_bases.get(cls, ()))
    while queue:
        base = queue.popleft()
        if base in seen:
            continue
        seen.add(base)
        queue.extend(index.class_bases.get(base, ()))
    return seen


def _is_contract_class(cls: str, index: ProjectIndex) -> bool:
    """True if ``cls`` inherits an interface base (Protocol/ABC), even indirectly."""
    return bool(_ancestors(cls, index) & CONTRACT_BASES)


def _has_external_base(cls: str, index: ProjectIndex) -> bool:
    """True if ``cls`` has a direct base defined outside the project."""
    return any(base != "object" and base not in index.project_classes for base in index.class_bases.get(cls, ()))


def _member_is_contract(item: UnusedItem, index: ProjectIndex) -> bool:
    """True if a method/attribute satisfies an interface the owning class inherits."""
    owner = _owning_class(item, index)
    if owner is None:
        return False
    # An external base hides its interface, so a public member may be an override.
    if _has_external_base(owner, index):
        return True
    return any(_is_contract_class(anc, index) and item.name in index.methods.get(anc, ()) for anc in _ancestors(owner, index) if anc in index.project_classes)


def _param_is_contract(item: UnusedItem, index: ProjectIndex) -> bool:
    """True if a parameter belongs to a decorated or interface-bound function."""
    if any(d.decorators for d in _declaring_funcs(item, index)):
        return True
    owner = _owning_class(item, index)
    if owner is None:
        return False
    return _has_external_base(owner, index) or _is_contract_class(owner, index)


def gather_evidence(item: UnusedItem, index: ProjectIndex) -> Evidence:
    ev = Evidence()
    name = item.name

    ev.is_parameter = item.typ == "variable" and bool(_declaring_funcs(item, index))

    if ev.is_parameter:
        ev.overrides_contract = _param_is_contract(item, index)
    else:
        ev.own_decorators = _own_decorators(item, index)
        ev.framework_decorated = _framework_decorated(ev.own_decorators)
        ev.contract_decorated = any(d.rsplit(".", 1)[-1] in CONTRACT_DECORATORS for d in ev.own_decorators)
        ev.overrides_contract = item.typ in ("method", "property", "attribute") and _member_is_contract(item, index)

    ev.decorator_uses = index.decorator_uses.get(name, 0)
    ev.string_uses = index.string_refs.get(name, 0)
    ev.dynamic = name in index.dynamic_refs
    ev.in_all = name in index.all_exports
    ev.in_init = item.filename.name == "__init__.py"
    ev.is_dunder = name.startswith("__") and name.endswith("__")
    ev.reachable = name in index.reachable
    ev.in_dynamic_module = item.filename in index.dynamic_modules

    for _file, is_test in index.reads.get(name, ()):
        if is_test:
            ev.test_refs += 1
        else:
            ev.prod_refs += 1

    return ev


def classify(ev: Evidence) -> Outcome:
    reasons = ev.reasons

    if ev.in_all or ev.in_init:
        reasons.append("Exported in __all__." if ev.in_all else "Defined in __init__.py.")
        return _outcome(Verdict.PUBLIC_API, Category.KEEP)

    if ev.framework_decorated or ev.decorator_uses > 0:
        reasons.append(f"Decorated with @{', @'.join(ev.own_decorators)}." if ev.own_decorators else f"Used as a decorator {ev.decorator_uses} time(s).")
        return _outcome(Verdict.FRAMEWORK_CODE, Category.KEEP)

    if ev.contract_decorated or ev.overrides_contract or ev.is_dunder:
        reasons.append("Interface contract (inherited, abstract, or dunder).")
        return _outcome(Verdict.FRAMEWORK_CODE, Category.KEEP)

    if ev.string_uses > 0 or ev.dynamic:
        reasons.append("Referenced through getattr/hasattr/setattr." if ev.dynamic else f"Appears in {ev.string_uses} string literal(s).")
        return _outcome(Verdict.DYNAMIC_USAGE, Category.KEEP)

    if ev.in_dynamic_module:
        reasons.append("File uses a dynamic surface (getattr/globals/importlib); reachability is unreliable.")
        return _outcome(Verdict.UNUSED, Category.REVIEW)

    if ev.is_parameter:
        reasons.append("Unused parameter with no interface contract.")
        return _outcome(Verdict.UNUSED, Category.REMOVE, note="unused parameter")

    if ev.reachable:
        reasons.append("Reachable from a production entry point.")
        return _outcome(Verdict.IN_USE, Category.FALSE_POSITIVE)

    if ev.test_refs > 0 and ev.prod_refs == 0:
        reasons.append("Referenced only from tests.")
        return _outcome(Verdict.TEST_ONLY, Category.TEST_ONLY)

    if ev.prod_refs > 0:
        reasons.append("Referenced only from code that is itself unreachable.")
        return _outcome(Verdict.DEAD_CHAIN, Category.REMOVE_CHAIN)

    reasons.append("Unreachable and unreferenced.")
    return _outcome(Verdict.UNUSED, Category.REMOVE)


_RISK = {
    Category.KEEP: Risk.HIGH,
    Category.FALSE_POSITIVE: Risk.HIGH,
    Category.REVIEW: Risk.MEDIUM,
    Category.TEST_ONLY: Risk.MEDIUM,
    Category.REMOVE: Risk.LOW,
    Category.REMOVE_CHAIN: Risk.LOW,
}

_RECOMMENDATION = {
    Category.KEEP: ("DO NOT REMOVE - framework, dynamic, or public API", "red"),
    Category.FALSE_POSITIVE: ("FALSE POSITIVE - reachable in production", "red"),
    Category.REVIEW: ("REVIEW - dynamic surface prevents a static verdict", "yellow"),
    Category.TEST_ONLY: ("REVIEW - referenced only by tests", "yellow"),
    Category.REMOVE: ("SAFE TO REMOVE", "green"),
    Category.REMOVE_CHAIN: ("REMOVE WITH CHAIN - part of a dead code chain", "green"),
}


def _outcome(verdict: Verdict, category: Category, note: str = "") -> Outcome:
    recommendation, style = _RECOMMENDATION[category]
    if note:
        recommendation = f"{recommendation} ({note})"
    return Outcome(verdict, _RISK[category], category, recommendation, style)


# --------------------------------------------------------------------------- #
# Output
# --------------------------------------------------------------------------- #


def show_code_context(item: UnusedItem, ctx_lines: int = 2) -> None:
    try:
        lines = item.filename.read_text(encoding="utf-8").splitlines()
    except OSError, UnicodeDecodeError:
        return

    start = max(1, item.lineno - ctx_lines)
    end = min(len(lines), item.lineno + ctx_lines)
    snippet = "\n".join(lines[start - 1 : end])
    console.print(Syntax(snippet, "python", line_numbers=True, start_line=start, highlight_lines={item.lineno}, word_wrap=True))


def report_item(index_pos: int, total: int, item: UnusedItem, ev: Evidence, outcome: Outcome, verbose: int) -> None:
    kind = "parameter" if ev.is_parameter else item.typ
    console.rule(f"[bold]\\[{index_pos}/{total}] {item.name}[/bold] [dim]({kind})[/dim]", align="left")
    console.print(f"[dim]{item.filename}:{item.lineno}  confidence {item.confidence}%[/dim]")

    if verbose >= 2:
        show_code_context(item)

    console.print(f"references: [green]{ev.prod_refs} prod[/green] · [cyan]{ev.test_refs} test[/cyan]")

    for reason in ev.reasons:
        console.print(f"  [dim]-[/dim] {reason}")

    if verbose >= 3:
        _dynamic_insights(item, ev)

    verdict_text = Text(f"{outcome.verdict}  ", style="bold")
    verdict_text.append(f"risk {outcome.risk}", style=_risk_style(outcome.risk))
    console.print(verdict_text)
    console.print(Text(outcome.recommendation, style=f"bold {outcome.style}"))


def _risk_style(risk: Risk) -> str:
    return {Risk.LOW: "green", Risk.MEDIUM: "yellow", Risk.HIGH: "red"}[risk]


def _dynamic_insights(item: UnusedItem, ev: Evidence) -> None:
    notes: list[str] = []
    if ev.own_decorators:
        notes.append(f"decorators: {', '.join('@' + d for d in ev.own_decorators)}")
    if INTERFACE_PREFIX_RE.search(item.name):
        notes.append("name suggests a required interface")
    if ev.in_dynamic_module:
        notes.append("file exposes a dynamic surface")
    if ev.dynamic:
        notes.append("reached through dynamic attribute access")
    if notes:
        body = "\n".join(f"- {n}" for n in notes)
        console.print(Panel(body, title="dynamic insights", title_align="left", border_style="cyan", expand=False))


def summary(results: list[tuple[UnusedItem, Evidence, Outcome]]) -> None:
    console.rule("[bold]SUMMARY", align="left")

    grouped: dict[Category, list[tuple[UnusedItem, Evidence, Outcome]]] = defaultdict(list)
    for row in results:
        grouped[row[2].category].append(row)

    safe = len(grouped[Category.REMOVE]) + len(grouped[Category.REMOVE_CHAIN])
    review = len(grouped[Category.REVIEW]) + len(grouped[Category.TEST_ONLY])
    keep = len(grouped[Category.KEEP]) + len(grouped[Category.FALSE_POSITIVE])

    stats = Table.grid(padding=(0, 2))
    stats.add_row("Total analyzed", str(len(results)))
    stats.add_row(Text("Safe to remove", style="green"), Text(str(safe), style="green"))
    stats.add_row(Text("Needs review", style="yellow"), Text(str(review), style="yellow"))
    stats.add_row(Text("Do not remove", style="red"), Text(str(keep), style="red"))
    console.print(stats)

    for category, (label, style) in CATEGORY_LABELS.items():
        rows = grouped.get(category)
        if not rows:
            continue
        table = Table(title=f"[{style}]{label}[/{style}]", title_justify="left", show_header=True, header_style="dim")
        table.add_column("symbol", style=style, no_wrap=True)
        table.add_column("type", style="dim")
        table.add_column("location")
        for item, ev, _ in sorted(rows, key=lambda r: r[0].name):
            kind = "parameter" if ev.is_parameter else item.typ
            table.add_row(item.name, kind, f"{item.filename}:{item.lineno}")
        console.print(table)


# --------------------------------------------------------------------------- #
# File discovery
# --------------------------------------------------------------------------- #


def _git_root(path: Path) -> Path:
    """Return the git top-level directory that contains ``path``."""
    anchor = path if path.is_dir() else path.parent
    result = subprocess.run(
        ["git", "-C", str(anchor), "rev-parse", "--show-toplevel"],
        capture_output=True,
        text=True,
        check=True,
    )
    return Path(result.stdout.strip())


def collect_py_files(sources: list[Path]) -> tuple[list[Path], set[Path]]:
    """Return ``*.py`` files under ``sources`` and the git roots that hold them.

    Use ``git ls-files`` so the walk honors .gitignore and skips paths git does
    not track, such as ``.venv``. Git never descends into a symlinked directory,
    so a ``.venv`` symlink is safe as well. Anchor git to each source's repo root
    with ``-C`` and request ``--full-name`` output, so the result is correct no
    matter what the cwd is or whether the source path is relative or absolute.
    """
    by_root: dict[Path, list[Path]] = defaultdict(list)
    for source in sources:
        by_root[_git_root(source.resolve())].append(source.resolve())

    files: set[Path] = set()
    for root, root_sources in by_root.items():
        result = subprocess.run(
            [
                "git",
                "-C",
                str(root),
                "ls-files",
                "--cached",
                "--others",
                "--exclude-standard",
                "--full-name",
                "-z",
                "--",
                *map(str, root_sources),
            ],
            capture_output=True,
            text=True,
            check=True,
        )
        files.update(path for entry in result.stdout.split("\0") if entry.endswith(".py") and (path := root / entry).is_file())

    return sorted(files), set(by_root)


def run_vulture(files: list[Path], min_confidence: int) -> list[UnusedItem]:
    vulture = Vulture()
    vulture.scavenge([str(f) for f in files])
    return [
        UnusedItem(
            name=item.name,
            filename=Path(item.filename).resolve(),
            lineno=item.first_lineno,
            typ=item.typ,
            confidence=item.confidence,
        )
        for item in vulture.get_unused_code(min_confidence=min_confidence)
    ]


def is_suppressed(item: UnusedItem, ev: Evidence, index: ProjectIndex, ignore: set[str]) -> bool:
    """True if the finding should not surface at all."""
    if item.name in ignore or item.lineno in index.noqa.get(item.filename, ()):
        return True
    # Conventional parameters (*args, **kwargs, leading underscore, self/cls) are intentional.
    return ev.is_parameter and (item.name in CONVENTION_PARAMS or item.name.startswith("_"))


# --------------------------------------------------------------------------- #
# Main
# --------------------------------------------------------------------------- #


app = typer.Typer(add_completion=False, help="Vulture dead code analysis with AST evidence.")


@app.command()
def main(
    sources: Annotated[
        list[Path] | None,
        typer.Argument(help="source paths to scan (files or directories; default: current directory)"),
    ] = None,
    min_confidence: Annotated[int, typer.Option(help="Vulture minimum confidence")] = 100,
    test_pattern: Annotated[str, typer.Option(help="regex marking a path as a test file")] = r"test_|_test\.py|/tests?/|conftest\.py",
    ignore: Annotated[list[str] | None, typer.Option(help="symbol name to never report (repeatable)")] = None,
    verbose: Annotated[int, typer.Option("--verbose", "-v", count=True, help="-v per-symbol detail, -vv code context, -vvv dynamic insights")] = 0,
) -> None:
    sources = sources or [Path.cwd()]
    ignore_names = set(ignore or ())

    try:
        files, roots = collect_py_files(sources)
    except (subprocess.CalledProcessError, FileNotFoundError) as exc:
        console.print(f"[red]git ls-files failed: {exc}[/red]")
        raise typer.Exit(code=1) from exc

    if not files:
        console.print(f"[yellow]No Python files found under: {', '.join(map(str, sources))}[/yellow]")
        return

    test_re = re.compile(test_pattern)

    console.print(
        Panel(
            f"sources: {', '.join(map(str, sources))}\nfiles: {len(files)}\nconfidence: {min_confidence}%\nverbose: {verbose}",
            title="Vulture dead code analysis",
            title_align="left",
            border_style="bold",
            expand=False,
        )
    )

    items = run_vulture(files, min_confidence)
    if not items:
        console.print("[green]No dead code detected by Vulture.[/green]")
        return

    console.print(f"[yellow]Vulture found {len(items)} potential dead code item(s).[/yellow]")

    dead_files = {item.filename for item in items}
    index = build_index(files, test_re, dead_files)
    index.entry_points = load_entry_points(roots)
    index.reachable = _reachability(index)

    results: list[tuple[UnusedItem, Evidence, Outcome]] = []
    for item in sorted(items, key=lambda i: (str(i.filename), i.lineno)):
        ev = gather_evidence(item, index)
        if is_suppressed(item, ev, index, ignore_names):
            continue
        results.append((item, ev, classify(ev)))

    total = len(results)
    for pos, (item, ev, outcome) in enumerate(results, start=1):
        if verbose >= 1:
            report_item(pos, total, item, ev, outcome, verbose)

    if not results:
        console.print("[green]All findings were suppressed or resolved.[/green]")
        return

    summary(results)


if __name__ == "__main__":
    app()
