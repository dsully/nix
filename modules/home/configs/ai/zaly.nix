{
  ai,
  lib,
  pkgs,
  ...
}: {
  imports = [../../programs/zaly];

  # zaly reads user instructions from $XDG_CONFIG_HOME/zaly/AGENTS.md (falling
  # back to ~/.agents/AGENTS.md). It has no dedicated rules mechanism, so the
  # shared language rules are folded into the same file — mirroring how codex
  # embeds `rulesMarkdown` into its context. zaly has no MCP client, so MCP
  # servers can't be wired. Skills come from the agent-skills `zaly` target.
  xdg.configFile."zaly/AGENTS.md".text = ''
    ${builtins.readFile ./AGENTS.md}
    ${ai.rulesMarkdown}
  '';

  programs.zaly = {
    enable = true;

    # Run zaly under bun instead of its default nodejs runtime. buildNpmPackage
    # still uses npm/node to fetch deps; we only repoint the generated bin wrapper.
    #
    # zaly 0.0.5's `#ansi`/`#glob` subpath imports have a `bun` condition pointing
    # at TypeScript sources under src/ that the npm tarball omits — so the bun
    # runtime can't resolve them and every TTY command aborts. The built bun
    # variants (dist/*.bun.mjs) *are* shipped, so repoint the conditions at those.
    package = pkgs.llm-agents.zaly.overrideAttrs (old: {
      postFixup =
        (old.postFixup or "")
        + ''
          substituteInPlace $out/bin/zaly \
            --replace-fail "${lib.getExe pkgs.nodejs}" "${lib.getExe pkgs.bun}"

          for pj in $(find $out/lib/node_modules -path '*@zaly/shared/package.json'); do
            substituteInPlace "$pj" \
              --replace-fail './src/runtime/ansi.bun.ts' './dist/ansi.bun.mjs' \
              --replace-fail './src/runtime/glob.bun.ts' './dist/glob.bun.mjs'
          done
        '';
    });

    reasoning = "medium";

    permissions = {
      preset = "permissive";

      # The permissive preset auto-allows destructive git history/worktree ops;
      # deny the ones forbidden by policy (never checkout/restore/stash/reset).
      deny = [
        "bash(git checkout:*)"
        "bash(git restore:*)"
        "bash(git stash:*)"
        "bash(git reset:*)"
      ];
    };

    ui.theme = "nord";
  };
}
