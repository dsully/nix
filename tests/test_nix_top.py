from pathlib import Path
from typing import Any

from scripts.nix_top import GcState, collapse, kept_by, parse, pname, reclaimable, referrers, root_label, split_name, strip_hashes, top_rows, version

S = "/nix/store/"
OLD, NEW, APP, LIB = f"{S}a-glibc-2.39", f"{S}b-glibc-2.40", f"{S}c-hello-1.0", f"{S}d-libfoo-3"

INFO: list[dict[str, Any]] = [
    {"path": OLD, "narSize": 30, "references": [OLD]},
    {"path": NEW, "narSize": 40, "references": [NEW]},
    {"path": LIB, "narSize": 50, "references": [NEW]},
    {"path": APP, "narSize": 5, "references": [APP, LIB, NEW]},
]


def test_pname_strips_hash_version_and_drv() -> None:
    assert pname(f"{S}abc-python3.14-rich-14.0.0") == "python3.14-rich"
    assert pname(f"{S}abc-hello-2.12.drv") == "hello"


def test_parse_accepts_list_and_keyed_object() -> None:
    keyed = {i["path"]: {k: v for k, v in i.items() if k != "path"} for i in INFO} | {f"{S}gone": None}

    assert parse(INFO) == parse(keyed)


def test_group_sums_versions_and_excludes_self_references() -> None:
    infos = parse(INFO)
    rows = top_rows(infos, 10, group=True)
    glibc = next(r for r in rows if pname(r.members[0]) == "glibc")

    assert glibc.size == 70
    assert referrers(infos, rows)[glibc] == ["hello", "libfoo"]


def test_count_limits_and_leaf_has_no_referrers() -> None:
    infos = parse(INFO)
    rows = top_rows(infos, 10)
    app = next(r for r in rows if r.members == (APP,))

    assert {r.members[0] for r in top_rows(infos, 2)} == {LIB, NEW}
    assert referrers(infos, rows)[app] == []


def test_strip_hashes_keeps_names_and_non_store_text() -> None:
    hashed = f"└───{S}0jb1qn7qnpbz8774mq5k2c1p84gp0x76-python3-3.14.8 {S}not-a-hash"

    assert strip_hashes(hashed) == f"└───python3-3.14.8 {S}not-a-hash"


def test_split_name_and_version_ignore_output_and_drv_suffixes() -> None:
    assert split_name(f"{S}abc-llvm-21.1.8-lib") == ("llvm", "21.1.8-lib")
    assert version(f"{S}abc-llvm-21.1.8-lib") == version(f"{S}abc-llvm-21.1.8.drv") == "21.1.8"
    assert split_name(f"{S}abc-source") == ("source", "")


def test_root_label_names_generations_processes_and_dev_shells(tmp_path: Path) -> None:
    profile = tmp_path / "home-manager"
    profile.symlink_to("home-manager-2-link")

    assert root_label(str(tmp_path / "home-manager-2-link"), {}) == "home"
    assert root_label(str(tmp_path / "home-manager-1-link"), {}) == "old home"
    assert root_label("{libproc/42/environ}", {"42": "fish"}) == "process fish 42"
    assert root_label("{libproc/43/region}", {}) == "process exited 43"
    assert root_label("/proc/7/maps", {"7": "nvim"}) == "process nvim 7"
    assert root_label("{censored}", {}) == "process censored ?"
    assert root_label("/src/proj/.direnv/flake-profile-1-link", {}) == "direnv proj"
    assert root_label("/src/proj/.direnv/nix-profile", {}) == "direnv proj"


def test_kept_by_follows_references_and_derivers_and_marks_dead() -> None:
    drv, gone = f"{S}e-hello-1.0.drv", f"{S}f-junk"
    infos = [
        *parse(INFO)[:3],
        *parse([{"path": APP, "narSize": 5, "references": [LIB], "deriver": drv}, {"path": drv, "narSize": 1}, {"path": gone, "narSize": 9}]),
    ]

    keepers = kept_by(infos, GcState(roots={"system": {APP}, "old home": {OLD}}, dead={gone}))

    assert keepers[NEW] == keepers[drv] == {"system"}
    assert keepers[OLD] == {"old home"}
    assert keepers[gone] == {"dead"}


def test_reclaimable_counts_only_paths_held_by_that_label_alone() -> None:
    infos = parse(INFO)
    keepers = {OLD: {"old home"}, NEW: {"old home", "process fish 1"}, LIB: {"dead"}, APP: {"process fish 1", "process nvim 2"}}

    freed, holders = reclaimable(infos, keepers)

    assert freed == {"dead": 50, "old home": 30, "processes": 5}
    assert set(holders) == {"process fish 1", "process nvim 2"}
    assert collapse("process fish 1") == "process fish"
    assert collapse("old home") == "old home"
