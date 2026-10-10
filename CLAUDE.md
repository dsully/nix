# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Personal Nix configuration for macOS (`nix-darwin`) and Linux (`system-manager` + `home-manager`).
Single user `dsully`, five hosts: `jarvis` (aarch64-darwin); `server`, `zap`, `ca`, `tnt` (x86_64-linux; `ca`/`tnt` have no home config).

## Commands

All day-to-day operations go through the `Justfile` (run `just` for the list):

- `just system [args]` — build/activate the host system config. On macOS uses `nh darwin switch`; on Linux uses `system-manager switch`.
- `just switch [args]` — activate the standalone home-manager config (`nh home switch -b backup`). On `server` it adds `--impure --refresh`.
- `just fmt` (aka `just format` / `just lint`) — run `alejandra .`, `deadnix .`, `statix check`. Always run before committing Nix changes.
- `just up` — `nix flake update` (update all inputs).
- `just gc` / `just clean` — garbage collect via `nh clean`.
- `just push-cache` — build every package in `packages/` and push to the `dsully` cachix cache.
- `just init-from-url <github-url>` — scaffold a new `packages/<name>.nix` via `nix-package-add` (nurl-based).

`.github/workflows/update.yml` runs the CI equivalent weekly (and on manual dispatch): it updates `flake.lock`, runs `nix-package-updater --cache` on Linux + macOS to bump `packages/*.nix` and push builds to the `dsully` cachix cache, then commits both back to `main`. Requires the `CACHIX_AUTH_TOKEN` repo secret.

Building / checking individual outputs (system is inferred):

- `nix build .#<pkg-name>` — build one package from `packages/`.
- `nix flake check` — runs all `pkg-<name>` checks; on Linux also runs the `formatting` check (`formatter.nix`'s `passthru.tests.check`, which fails if `alejandra`/`deadnix`/`statix` would change anything).
- `nix build .#formatter` — build the combined format+lint wrapper.

A `devshell` (`nix develop` / direnv `.envrc`) provides `alejandra cachix deadnix fd fish jq just nh nurl ripgrep sd statix nix-package-updater`.

## Architecture

Capability-module layout adapted from fersilva16's config. Home-manager stays **standalone** (`just switch`), so every capability module is evaluated twice: once in the system config (nix-darwin / system-manager) and once in the standalone home-manager config.

```
lib/mkDarwinHost.nix          # host factory → { system; homeConfigurations }
lib/mkSystemManagerHost.nix   # same interface for system-manager hosts
lib/hostLib.nix               # mkHost: shared body of both host factories (fields documented here)
lib/mkUserModule.nix          # per-user capability with modules.users.<user>.<name>.enable
lib/mkSystemModule.nix        # host capability with modules.system.<name>.enable
modules/hosts/<host>.nix      # factory call; host-only files under modules/hosts/<host>/
modules/<category>/<app>.nix  # capability modules, auto-discovered
modules/<category>/<app>/<app>.nix  # capability with helper files beside it
```

### Flake assembly (`flake.nix`)

Hand-rolled `flake-parts` flake. `packages/` is auto-discovered: every `*.nix` file or subdirectory with `default.nix` becomes a `callPackage`d output. Every `modules/hosts/<host>.nix` is discovered; the factory it takes (`{mkDarwinHost}` or `{mkSystemManagerHost}`) decides its system, and it is called with that factory bound to the system's overlaid `pkgs`. Outputs:

- `darwinConfigurations.jarvis`, `systemConfigs.{ca,server,tnt,zap}` — the hosts' `.system`.
- `legacyPackages.<system>.homeConfigurations."<user>@<host>"` — the hosts' `.homeConfigurations`.
- `lib.{mkDarwinHost, mkSystemManagerHost, discoverPackages}` and `overlays.default` — for the work flake (`~/dev/work/nix`), which builds its hosts with these factories (`{ inputs, pkgs, packages, extraModuleDirs }`; the factories derive the `flake` and `perSystem` specialArgs) and adds its own module tree via `extraModuleDirs`.

### Two evaluation targets

`lib/hostLib.nix` passes `userModuleTarget` as a specialArg:

- `"system"` — `mkUserModule` applies `system`, `casks`, `user`; `mkSystemModule` applies `config`.
- `"home"` (with `homeUser`) — `mkUserModule` applies `home` (and enabled `parts`) at the top level and declares `homeOptions`; `mkSystemModule` contributes nothing.

Discovery excludes `hosts`/`users` everywhere, `linux` on darwin, `darwin` on system-manager, and both `darwin` and `linux` in home configs. So `modules/darwin/` and `modules/linux/` are system-only; every other category must evaluate in both targets. Inside a module, `config` is the config of the current evaluation (home-manager config inside `home`, system config inside `system`). The top-level attribute names returned by a `home` function must not depend on `cfg`/`userCfg`.

### Hosts and users

Every `mkUserModule` is on by default; host-specific ones declare `default = false`. Each host has one user (`user`, default `dsully`; `homeStateVersion` default `"25.05"`; `home = false` for hosts without a home config). A host turns modules on or off with `userConfig.<module>.enable`. Other host fields: `extraModules` (system) and `extraHomeModules` (plain home-manager modules for host-only data such as topgrade repos and server's vopono units). `mkUserModule` relations: `requires` turns other modules on; `needs` applies `home` only while other modules are on. Host-only service modules (`modules/linux/{caddy,docker,opnix,beszel-agent,tailscale}.nix`) default to off; hosts set `modules.system.<name>.enable`.

### Plain modules every evaluation imports

- `modules/system/nix.nix` — custom `system.*` options: `system.hostName` (set by the host factory), `system.userName` (primary user / home user), `system.fullName`, `system.primaryGroup`, `system.nixFlavor` (enum `cppnix`/`determinate`/`lix`, **default `lix`**), `system.nixSettings`, `system.sudoRules` + `sudoLib`. The binary-cache substituters (cache.nixos.org, **dsully.cachix.org**, numtide, nix-community, lix) live here.
- `modules/system/base.nix` — home-only external module imports (agent-skills, nix-index-database, opnix), `disabledModules`, and `_module.args.my.pkgs`.
- `modules/system/colors.nix` — the read-only `colors` palette.

### Package injection: `my.pkgs`, `perSystem.self`, `perSystem.upstream`

- `perSystem.self` — this flake's `packages.<system>`. Consuming flakes set `perSystem.upstream` instead; modules read `perSystem.upstream or perSystem.self`.
- `my.pkgs` — `pkgs` extended with `perSystem.{upstream,self}`. Use `with my.pkgs; [...]` to pull in repo-local tools (`devmoji-log`, `lolcate-rs`, `safari-rs`, …).

### Program configs and dotfiles

- `modules/system/dotfiles.nix` — links `dotfiles/` into `~/.config`. **Recursive directories** (fish conf.d/functions/completions) use the **flake-relative path** so they copy into the store; **live-editable single files** use `mkOutOfStoreSymlink` pointing at `dotfiles.dir` (default `~/.config/nix/dotfiles`) so edits apply without a rebuild.
- uv-managed CLI tools: append to `programs.uv.tool.packages` from any capability (e.g. `modules/networking/unifi.nix`).

### AI tooling (`modules/ai/`)

`modules/ai/ai.nix` is the core capability: it builds the registry (`registry.nix`, `hooks.nix`, `permissions.nix`) and exposes it as `_module.args.ai` (helpers like `ai.muxWrap`). `ai` `requires` the default tools (`ccstatusline`, `claude-code`, `herdr`, `mcp-mux`, `opencode`, `skills`), so `ai.enable` alone turns the set on or off and a host disables one tool with `<tool>.enable = false`. Tools that read the `ai` arg (`claude-code`, `codex`, `opencode`, `pi`, `mcp-mux`, `unifi`) declare `needs = ["ai"]` instead of `requires`, which would cycle; `meridian` requires `claude-code`. `skills` merges `commands.nix`/`superpowers.nix`, and `pi` merges `theme.nix`, as fragments. Shared content (`AGENTS.md`, `rules/`, `output-styles/`, `plugins/`, `hooks/`) lives in `modules/ai/shared/`.

### Secrets — 1Password via opnix

`programs.onepassword-secrets` (opnix) materializes secrets from 1Password (`op://...` references) to files at activation time. Home-activation scripts in the `checkip` and `zoned` capabilities (`checkipConfig`, `zonedConfig`) then template config files from those secret files, gated on their existence and `entryAfter ["onepassword-secrets"]`.

## Conventions

- Nix files are 2-space indent, formatted by **alejandra**, dead-code-checked by **deadnix**, linted by **statix**. CI (`formatter.nix` check, Linux-only) fails on any unformatted file.
- New packages: prefer `rustPlatform.buildRustPackage` with a pinned `fetchFromGitHub` `rev`/`hash` + `cargoHash`, `doCheck = false`, and a `meta` block with `mainProgram`. Scaffold with `just init-from-url`. Most existing packages follow this exact shape.
- `scripts/check_upstream_packages.py` (entry point `check-upstream-packages`, Python 3.14, managed by `uv`/`pyproject.toml`) checks whether pinned package versions are behind upstream.
- Bootstrap a new machine with `scripts/bootstrap.sh --host <name>`.
