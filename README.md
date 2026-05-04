# nix

Personal Nix configuration for macOS (`nix-darwin`) and Linux (`system-manager` + `home-manager`).

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
