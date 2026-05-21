#!/usr/bin/env python3

"""Rewrite source files in place, replacing problematic Unicode characters.

Mirrors PROBLEMATIC_CHARS from src/constants/characters.ts but targets source
code rather than HTML.
"""

from __future__ import annotations

import sys

from collections.abc import Generator
from pathlib import Path

REPLACEMENTS: dict[str, str] = {
    # Smart quotes
    "\u201c": '"',  # Left double quotation mark
    "\u201d": '"',  # Right double quotation mark
    "\u2018": "'",  # Left single quotation mark
    "\u2019": "'",  # Right single quotation mark
    "\u201a": "'",  # Single low-9 quotation mark
    "\u201e": '"',  # Double low-9 quotation mark
    "\u00ab": '"',  # Left-pointing double angle quotation mark
    "\u00bb": '"',  # Right-pointing double angle quotation mark
    "\u2039": "'",  # Single left-pointing angle quotation mark
    "\u203a": "'",  # Single right-pointing angle quotation mark
    # Dashes & hyphens
    "\u2013": "-",  # En dash
    "\u2014": "-",  # Em dash
    "\u2010": "-",  # Hyphen
    "\u2011": "-",  # Non-breaking hyphen
    "\u2012": "-",  # Figure dash
    "\u2015": "-",  # Horizontal bar
    # Invisible spaces
    "\u00a0": " ",  # Non-breaking space
    "\u2009": " ",  # Thin space
    "\u200a": " ",  # Hair space
    "\u2002": " ",  # En space
    "\u2003": " ",  # Em space
    "\u2028": "\n",  # Line separator
    "\u2029": "\n\n",  # Paragraph separator
    "\u202f": " ",  # Narrow no-break space
    "\u205f": " ",  # Medium mathematical space
    "\u3000": " ",  # Ideographic space
    # Punctuation
    "\u2026": "...",  # Horizontal ellipsis
    "\u2022": "*",  # Bullet
    "\u2023": "*",  # Triangular bullet
    "\u2043": "-",  # Hyphen bullet
    "\u00b7": "*",  # Middle dot
    "\u2032": "'",  # Prime
    "\u2033": '"',  # Double prime
    # Arrows
    "\u2190": "<-",  # Leftwards arrow
    "\u2191": "^",  # Upwards arrow
    "\u2192": "->",  # Rightwards arrow
    "\u2193": "v",  # Downwards arrow
    "\u2194": "<->",  # Left right arrow
    "\u21d0": "<=",  # Leftwards double arrow
    "\u21d2": "=>",  # Rightwards double arrow
    "\u21d4": "<=>",  # Left right double arrow
    "\u27f5": "<-",  # Long leftwards arrow
    "\u27f6": "->",  # Long rightwards arrow
    "\u27f7": "<->",  # Long left right arrow
    "\u27f8": "<=",  # Long leftwards double arrow
    "\u27f9": "=>",  # Long rightwards double arrow
    "\u27fa": "<=>",  # Long left right double arrow
    # Math operators
    "\u00d7": "*",  # Multiplication sign
    "\u00f7": "/",  # Division sign
    "\u2212": "-",  # Minus sign
    "\u00b1": "+/-",  # Plus-minus sign
    "\u2248": "~=",  # Almost equal to
    "\u2260": "!=",  # Not equal to
    "\u2264": "<=",  # Less-than or equal to
    "\u2265": ">=",  # Greater-than or equal to
    # Checks/marks
    "\u2713": "[x]",  # Check mark
    "\u2714": "[x]",  # Heavy check mark
    "\u2717": "[ ]",  # Ballot x
    "\u2718": "[ ]",  # Heavy ballot x
    # Trademark/copyright
    "\u00a9": "(c)",  # Copyright
    "\u00ae": "(R)",  # Registered
    "\u2122": "(TM)",  # Trademark
    # Ligatures
    "\ufb00": "ff",
    "\ufb01": "fi",
    "\ufb02": "fl",
    "\ufb03": "ffi",
    "\ufb04": "ffl",
    # Zero-width / invisible (strip entirely)
    "\u200b": "",  # Zero-width space
    "\u200c": "",  # Zero-width non-joiner
    "\u200d": "",  # Zero-width joiner
    "\u2060": "",  # Word joiner
    "\ufeff": "",  # BOM / zero-width no-break space
    "\u00ad": "",  # Soft hyphen
}

SOURCE_EXTENSIONS: frozenset[str] = frozenset(
    {
        ".bash",
        ".c",
        ".cc",
        ".cfg",
        ".conf",
        ".cpp",
        ".cs",
        ".css",
        ".cxx",
        ".dart",
        ".ex",
        ".exs",
        ".fish",
        ".go",
        ".h",
        ".hh",
        ".hpp",
        ".hxx",
        ".ini",
        ".java",
        ".js",
        ".json",
        ".jsx",
        ".kt",
        ".kts",
        ".lua",
        ".md",
        ".mjs",
        ".php",
        ".pl",
        ".pm",
        ".py",
        ".pyi",
        ".rb",
        ".rs",
        ".scala",
        ".sh",
        ".sql",
        ".swift",
        ".toml",
        ".ts",
        ".tsx",
        ".yaml",
        ".yml",
        ".zsh",
    }
)

SKIP_DIRS: frozenset[str] = frozenset(
    {
        ".git",
        ".hg",
        ".idea",
        ".mypy_cache",
        ".next",
        ".pytest_cache",
        ".ruff_cache",
        ".svn",
        ".tox",
        ".venv",
        ".vscode",
        "__pycache__",
        "build",
        "dist",
        "node_modules",
        "target",
        "venv",
    }
)


def fix_file(path: Path) -> int:
    """Replace problematic chars in `path`. Return number of replacements."""

    try:
        original = path.read_text(encoding="utf-8")
    except (UnicodeDecodeError, OSError):
        return 0

    replaced = original

    total = 0

    for bad, good in REPLACEMENTS.items():
        if count := replaced.count(bad):
            replaced = replaced.replace(bad, good)
            total += count

    if total:
        path.write_text(replaced, encoding="utf-8")

    return total


def iter_sources(root: Path) -> Generator[Path]:

    for path in root.rglob("*"):
        if not path.is_file():
            continue

        if any(part in SKIP_DIRS for part in path.parts):
            continue

        if path.suffix.lower() not in SOURCE_EXTENSIONS:
            continue

        yield path


def main(argv: list[str]) -> int:

    if len(argv) != 2:
        print(f"usage: {argv[0]} <directory>", file=sys.stderr)
        return 2

    root = Path(argv[1])

    if not root.is_dir():
        print(f"error: not a directory: {root}", file=sys.stderr)
        return 2

    files_changed = 0
    chars_changed = 0

    for path in iter_sources(root):
        if n := fix_file(path):
            files_changed += 1
            chars_changed += n
            print(f"{path}: {n}")

    print(f"\n{files_changed} file(s), {chars_changed} character(s) replaced")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
