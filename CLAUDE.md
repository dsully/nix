# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Personal Nix configuration for macOS (`nix-darwin`) and Linux (`system-manager` + `home-manager`).
Single user `dsully`, three hosts: `jarvis` (aarch64-darwin), `server` and `zap` (x86_64-linux).

## Commands

All day-to-day operations go through the `Justfile` (run `just` for the list):

- `just system [args]` — build/activate the host system config. On macOS uses `nh darwin switch`; on Linux uses `system-manager switch`.
- `just switch [args]` — activate the standalone home-manager config (`nh home switch -b backup`). On `server` it adds `--impure --refresh`.
- `just fmt` (aka `just format` / `just lint`) — run `alejandra .`, `deadnix .`, `statix check`. Always run before committing Nix changes.
- `just up` — `nix flake update` (update all inputs).
- `just gc` / `just clean` — garbage collect via `nh clean`.
- `just push-cache` — build every package in `packages/` and push to the `dsully` cachix cache.
- `just init-from-url <github-url>` — scaffold a new `packages/<name>.nix` via `nix-package-add` (nurl-based).

Building / checking individual outputs (system is inferred):

- `nix build .#<pkg-name>` — build one package from `packages/`.
- `nix flake check` — runs all `pkg-<name>` checks; on Linux also runs the `formatting` check (`formatter.nix`'s `passthru.tests.check`, which fails if `alejandra`/`deadnix`/`statix` would change anything).
- `nix build .#formatter` — build the combined format+lint wrapper.

A `devshell` (`nix develop` / direnv `.envrc`) provides `alejandra cachix deadnix fd fish jq just nh nurl ripgrep sd statix nix-package-updater`.

## Architecture

### Flake assembly (`flake.nix`)

Hand-rolled `flake-parts` flake (not Blueprint, but deliberately "Blueprint-compatible" — modules receive `flake` and `perSystem` via `specialArgs`/`extraSpecialArgs`). Key auto-discovery:

- **`packages/`** → flake packages. Every `*.nix` file or subdirectory with `default.nix` becomes a `callPackage`d output. A few get extra inputs via `packageOverrides` (e.g. `meridian` gets `claude-code`/`opencode` from the `llm-agents` input; `nh` gets `rom`).
- **`modules/home/*.nix`** → `homeModules.<name>`, except internal files `colors.nix` and `dotfiles.nix` (imported directly by `dsully.nix`). The `ai` directory is added explicitly as `homeModules.ai`.
- **`modules/darwin/{common,homebrew}.nix`** → `modules.darwin.*`.
- **`modules/system-manager/{common,opnix,caddy}.nix`** → `modules.system-manager.*`.

Three configuration entry points, each importing from `hosts/<host>/`:

- `darwinConfigurations.jarvis` — nix-darwin + home-manager-as-darwin-module. `hosts/jarvis/darwin-configuration.nix` force-disables the darwin-managed HM users (`home-manager.users = mkForce {}`); the real HM config is `hosts/jarvis/users/dsully.nix`.
- `systemConfigs.{server,zap}` — `system-manager` configs from `hosts/<host>/system-configuration.nix` (Linux).
- `legacyPackages.homeConfigurations."dsully@<host>"` — standalone home-manager (built by `just switch`). The `mkHome` builder overrides `mcp-nixos` to skip its checks.

### Host layout convention

Each `hosts/<host>/` has `options.nix` (sets `system.hostName` and other custom options), and `users/dsully.nix` (the home-manager entry point, importing the shared `flake.homeModules.*`). Darwin/system-manager hosts add `*-configuration.nix`; the server keeps raw config files under `hosts/server/files/`.

### Custom `system.*` options

`modules/common/nix.nix` defines a custom options namespace used everywhere instead of hardcoding values: `system.hostName`, `system.userName` (default `dsully`), `system.fullName`, `system.primaryGroup`, `system.nixFlavor` (enum `cppnix`/`determinate`/`lix`, **default `lix`**), and `system.nixSettings` (shared substituters/keys merged across flavors). The binary-cache substituters (cache.nixos.org, **dsully.cachix.org**, numtide, nix-community, lix) live here too.

### Package injection: `my.pkgs`, `perSystem.self`, `perSystem.upstream`

This flake's own packages are exposed to home-manager modules two ways:

- `perSystem.self` — this flake's `packages.<system>`. Consuming flakes set `perSystem.upstream` instead; modules read `perSystem.upstream or perSystem.self`.
- `my.pkgs` (`modules/home/dsully.nix`) — `pkgs` extended with all of `perSystem.{upstream,self}`. Use `with my.pkgs; [...]` in `modules/home/packages/` to pull in repo-local tools (`devmoji-log`, `lolcate-rs`, `safari-rs`, …).

### `packageTools.python` — uv-managed CLI tools

`modules/home/packages/python.nix` defines the `packageTools.python` option. Listed tools are installed at home-activation time via `uv tool install` (Python 3.14, `+gil` on Darwin) rather than baked into the store. Supports `extras`, `prerelease`, `withPackages`, `inject`. Hosts/users append to it (e.g. `unifi-mcp-server` in jarvis's user config).

### Program configs and dotfiles

- `modules/home/configs/` — per-tool home-manager config (`git.nix`, `fish.nix`, `ssh.nix`, `zellij.nix`, …), aggregated by `configs/default.nix`.
- `modules/home/dotfiles.nix` — links `dotfiles/` into `~/.config`. **Recursive directories** (fish conf.d/functions/completions) use the **flake-relative path** so they copy into the store; **live-editable single files** use `mkOutOfStoreSymlink` pointing at `~/.config/nix/dotfiles/...` so edits apply without a rebuild (note the comment explaining why recursive + out-of-store symlink breaks in sandbox builds).

### AI tooling (`modules/home/configs/ai/`)

Large subsystem configuring `claude-code`, `codex`, `opencode`, and related agents/skills/hooks. `ai/common.nix` is imported as a plain function and re-exposed to all AI submodules via `_module.args.ai`; it provides helpers like `ai.muxWrap` (wraps an MCP server command through mcp-mux). `claude-code`/`opencode` packages come from the `llm-agents` input; agents/skills from the `wshobson-agents`, `agent-skills`, `superpowers`, etc. inputs. `AGENTS.md` and `permissions.nix` define agent policy.

### Secrets — 1Password via opnix

`programs.onepassword-secrets` (opnix) materializes secrets from 1Password (`op://...` references) to files at activation time. Home-activation scripts in `dsully.nix` (`checkipConfig`, `zonedConfig`) then template config files from those secret files, gated on their existence and `entryAfter ["onepassword-secrets"]`.

## Conventions

- Nix files are 2-space indent, formatted by **alejandra**, dead-code-checked by **deadnix**, linted by **statix**. CI (`formatter.nix` check, Linux-only) fails on any unformatted file.
- New packages: prefer `rustPlatform.buildRustPackage` with a pinned `fetchFromGitHub` `rev`/`hash` + `cargoHash`, `doCheck = false`, and a `meta` block with `mainProgram`. Scaffold with `just init-from-url`. Most existing packages follow this exact shape.
- `scripts/check_upstream_packages.py` (entry point `check-upstream-packages`, Python 3.14, managed by `uv`/`pyproject.toml`) checks whether pinned package versions are behind upstream.
- Bootstrap a new machine with `scripts/bootstrap.sh --host <name>`.
