#!/usr/bin/env python3
"""Check whether custom packages in ./packages are now available in nixpkgs."""

import json
import re
import subprocess
import sys

from dataclasses import dataclass
from pathlib import Path

from rich.console import Console
from rich.table import Table

PLATFORMS = ("aarch64-darwin", "x86_64-linux")
PACKAGES_DIR = Path(__file__).parent.parent / "packages"

# Plain string assignments - covers version, rev, hash.
_ATTR_RE = re.compile(r'^\s*(\w+)\s*=\s*"([^"]+)"', re.MULTILINE)

console = Console()


@dataclass(frozen=True)
class LocalPackage:
    pname: str
    nix_file: Path
    # Cleaned version string suitable for display.
    local_version: str


@dataclass(frozen=True)
class Match:
    pkg: LocalPackage
    attr: str
    upstream_version: str


def parse_attrs(text: str) -> dict[str, str]:
    """Return all simple string assignments found in a Nix file."""
    return {m.group(1): m.group(2) for m in _ATTR_RE.finditer(text)}


def local_version(attrs: dict[str, str]) -> str:
    """
    Determine the best human-readable version label from parsed Nix attrs.

    Preference order:
      1. `version` - use as-is; if it embeds a `${rev}` interpolation the raw
         text will contain a literal `${rev}` which we replace with the actual
         rev value when available.
      2. `rev` alone - short-circuit to the first 8 chars (commit hash).
      3. `hash` - last resort, first 8 chars after the algorithm prefix.
    """
    version = attrs.get("version", "")
    rev = attrs.get("rev", "")

    if version:
        # version may be written as e.g. `"1.0.0-alpha.9-${rev}"` - the regex
        # captures the literal text including the interpolation marker.
        if "${rev}" in version and rev:
            version = version.replace("${rev}", rev[:8])
        elif version == rev:
            # Some packages set version = rev (full hash) - abbreviate.
            version = rev[:8]
        return version

    if rev:
        return rev[:8]

    if src_hash := attrs.get("hash", ""):
        # Strip the sri algorithm prefix (sha256-…) and abbreviate.
        _, _, digest = src_hash.partition("-")
        return digest[:8] if digest else src_hash[:8]

    return "?"


def collect_packages() -> list[LocalPackage]:
    """Return a LocalPackage for every package under PACKAGES_DIR."""
    packages: list[LocalPackage] = []

    for entry in sorted(PACKAGES_DIR.iterdir()):
        nix_file = (entry / "default.nix") if entry.is_dir() else entry

        if nix_file.suffix != ".nix" or not nix_file.exists():
            continue

        attrs = parse_attrs(nix_file.read_text())
        pname = attrs.get("pname")

        if not pname:
            continue

        packages.append(LocalPackage(pname=pname, nix_file=nix_file, local_version=local_version(attrs)))

    return packages


def search_nixpkgs(packages: list[LocalPackage]) -> list[Match]:
    """Return a Match for every package that is a top-level nixpkgs attribute available on all PLATFORMS.

    Evaluates the flake's locked nixpkgs input directly; `nh search` queries the
    search.nixos.org index, which misses exact names such as `dirstat-rs`.
    """
    names = json.dumps(json.dumps([pkg.pname for pkg in packages]))
    platforms = " ".join(f'"{p}"' for p in PLATFORMS)

    expr = f"""
      let
        pkgs = (builtins.getFlake "{PACKAGES_DIR.parent}").inputs.nixpkgs.legacyPackages.x86_64-linux;
        inherit (pkgs) lib;
        available = pkg: lib.all (p: lib.meta.availableOn (lib.systems.elaborate p) pkg) [{platforms}];
        lookup = n: builtins.tryEval (
          if pkgs ? ${{n}} && lib.isDerivation pkgs.${{n}} && available pkgs.${{n}}
          then pkgs.${{n}}.version or "?"
          else null
        );
      in
        lib.filterAttrs (_: v: v != null)
          (lib.genAttrs (builtins.fromJSON {names}) (n: let r = lookup n; in if r.success then r.value else null))
    """

    result = subprocess.run(
        ["nix", "eval", "--impure", "--json", "--expr", expr],
        capture_output=True,
        text=True,
        check=True,
    )

    upstream: dict[str, str] = json.loads(result.stdout)

    return [Match(pkg=pkg, attr=pkg.pname, upstream_version=upstream[pkg.pname]) for pkg in packages if pkg.pname in upstream]


def main() -> None:
    packages = collect_packages()

    if not packages:
        console.print(f"[red]No packages found in {PACKAGES_DIR}[/red]")
        sys.exit(1)

    with console.status("Searching nixpkgs…"):
        found = search_nixpkgs(packages)

    if not found:
        console.print("[green]✓[/green] None of your custom packages are in nixpkgs yet.")
        return

    table = Table(title=f"Custom packages available in nixpkgs\n[dim]{' · '.join(PLATFORMS)}[/dim]")
    table.add_column("pname", style="cyan", no_wrap=True)
    table.add_column("nixpkgs attribute", style="yellow", no_wrap=True)
    table.add_column("local", style="dim", justify="right")
    table.add_column("upstream", style="green", justify="right")

    for m in sorted(found, key=lambda m: m.pkg.pname):
        table.add_row(m.pkg.pname, f"nixpkgs#{m.attr}", m.pkg.local_version, m.upstream_version)

    console.print(table)


if __name__ == "__main__":
    main()
