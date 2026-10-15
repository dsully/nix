# nix

Personal Nix configuration for macOS (`nix-darwin`) and Linux (`system-manager` + `home-manager`).

## The Nix ecosystem

These names refer to different layers that build on each other:

- **[Nix](https://nix.dev/)**: two things share this name. One is a lazy, functional language for describing builds. The other is the package manager that evaluates that language and builds into `/nix/store`. [nixpkgs](https://github.com/NixOS/nixpkgs) is the large package collection written in it. This repo uses [Lix](https://lix.systems/), a Nix implementation, by default.
- **[NixOS](https://nixos.org/)**: a Linux distribution whose whole system (kernel, services, `/etc`) is built from Nix modules. No host here runs NixOS.
- **[nix-darwin](https://github.com/nix-darwin/nix-darwin)**: NixOS-style modules for macOS, covering system settings, `launchd` services, and Homebrew casks. Used on `jarvis`.
- **[system-manager](https://github.com/numtide/system-manager)**: NixOS-style modules for an existing Linux distribution (Ubuntu, Debian, …). It manages `/etc` files and `systemd` services without replacing the OS. Used on `server`, `zap`, `ca`, and `tnt`.
- **[home-manager](https://github.com/nix-community/home-manager)**: per-user configuration (packages, dotfiles, program settings in `~`). It runs on any of the above. This repo runs it standalone with `just switch`, separate from the system config applied by `just system`.

### Learning

- [Nix language tutorial](https://nix.dev/tutorials/nix-language): the official walkthrough of the language. Start here before reading any module.
- [NixOS & Flakes Book](https://nixos-and-flakes.thiscute.world/) ([source](https://github.com/ryan4yin/nixos-and-flakes-book)): a beginner guide to flakes and NixOS-style modules.
- [Zero to Nix](https://zero-to-nix.com/): a short, flakes-first introduction. It is written by Determinate Systems and recommends their installer; this repo defaults to Lix.
- [Nix Pills](https://nixos.org/guides/nix-pills/): how derivations and the store work underneath. It predates flakes.

### Reference

- [nixpkgs packages](https://search.nixos.org/packages) and [NixOS options](https://search.nixos.org/options) search
- [Home Manager options](https://home-manager-options.extranix.com/) search and [manual](https://nix-community.github.io/home-manager/)
- [nix-darwin manual](https://nix-darwin.github.io/nix-darwin/manual/), including the option list
- [Noogle](https://noogle.dev/): search `lib` and builtin functions
- [flake.parts](https://flake.parts/): the framework `flake.nix` is built on
- [Lix manual](https://docs.lix.systems/manual/lix/stable/)
- [NixOS Wiki](https://wiki.nixos.org/) and [NixOS Discourse](https://discourse.nixos.org/)

## Bootstrap

[`scripts/bootstrap.sh`](scripts/bootstrap.sh) takes a fresh machine to a fully activated configuration.

### Usage

Clone manually, then run:

```sh
git clone git@github.com:dsully/nix.git ~/.config/nix
~/.config/nix/scripts/bootstrap.sh --host <hostname>
```

Or run the script directly and let it clone the repo:

```sh
curl -fsSL https://raw.githubusercontent.com/dsully/nix/main/scripts/bootstrap.sh | bash -s -- --host jarvis
```

### Options

| Flag                | Description                                                             |
| ------------------- | ----------------------------------------------------------------------- |
| `--host <name>`     | Target host to validate and activate. Prompts on macOS if omitted.      |
| `--repo-dir <path>` | Path to the nix repo checkout. Defaults to `~/.config/nix`.             |
| `--skip-hostname`   | Skip renaming the machine; current hostname must already match `--host`. |
| `--help`            | Show usage.                                                             |

After bootstrap completes, restart your terminal to pick up the new environment.

## New laptop checklist

Transfer or unlink licenses for:

- BoltAI
- Cleanshot
- Camo Studio
- Downie
- Tower

![Repobeats](https://repobeats.axiom.co/api/embed/90bbf17ea51b753ccdc2a132b8f40c9ca1b5f1e6.svg "Repobeats analytics image")
