{
  lib,
  my,
  perSystem,
  pkgs,
}: let
  command = attrs: attrs // {type = "command";};

  hook = {
    name,
    command,
    targets ? ["claude" "codex"],
    timeout ? null,
    async ? null,
    statusMessage ? null,
  }:
    {
      inherit command name targets;
      type = "command";
    }
    // lib.optionalAttrs (timeout != null) {inherit timeout;}
    // lib.optionalAttrs (async != null) {inherit async;}
    // lib.optionalAttrs (statusMessage != null) {inherit statusMessage;};

  group = {
    matcher ? null,
    hooks,
  }:
    {
      inherit hooks;
    }
    // lib.optionalAttrs (matcher != null) {inherit matcher;};

  events = {
    PreCompact = [
      (group {
        hooks = [
          (hook {
            name = "icm-compact";
            command = "${lib.getExe my.pkgs.icm} hook compact";
          })
        ];
      })
    ];

    PreToolUse = [
      (group {
        matcher = "Bash";
        hooks = [
          (hook {
            name = "enforce-uv";
            command = "${./hooks/enforce-uv.fish}";
          })
          (hook {
            name = "rtk-rewrite";
            command = "${perSystem.llm-agents.rtk}/libexec/rtk/hooks/claude/rtk-rewrite.sh";
            targets = ["claude"];
          })
          (hook {
            name = "icm-pre";
            command = "${lib.getExe my.pkgs.icm} hook pre";
          })
        ];
      })
    ];

    PostToolUse = [
      (group {
        matcher = "Edit|Write|MultiEdit";
        hooks = [
          (hook {
            name = "format-written-file";
            command =
              # bash
              ''
                file_path="$1"
                case "$file_path" in
                  *.nix)   ${lib.getExe pkgs.alejandra} "$file_path" 2>/dev/null || true ;;
                  *.py)    ${lib.getExe pkgs.ruff} format "$file_path" 2>/dev/null || true ;;
                  *.rs)    rustfmt +nightly "$file_path" 2>/dev/null || true ;;
                esac
              '';
            targets = ["claude"];
            timeout = 10;
          })
          (hook {
            name = "icm-post";
            command = "${lib.getExe my.pkgs.icm} hook post";
          })
        ];
      })
    ];

    SessionStart = [
      (group {
        hooks = [
          (hook {
            name = "icm-start";
            command = "${lib.getExe my.pkgs.icm} hook start";
          })
        ];
      })
    ];

    UserPromptSubmit = [
      (group {
        hooks = [
          (hook {
            name = "icm-prompt";
            command = "${lib.getExe my.pkgs.icm} hook prompt";
          })
        ];
      })
    ];
  };

  supportsTarget = target: hookDef: builtins.elem target hookDef.targets;

  renderHook = hookDef:
    command (
      {
        inherit (hookDef) command;
      }
      // lib.optionalAttrs (hookDef ? timeout) {inherit (hookDef) timeout;}
      // lib.optionalAttrs (hookDef ? async) {inherit (hookDef) async;}
      // lib.optionalAttrs (hookDef ? statusMessage) {inherit (hookDef) statusMessage;}
    );

  renderGroup = target: groupDef: let
    renderedHooks = map renderHook (builtins.filter (supportsTarget target) groupDef.hooks);
  in
    if renderedHooks == []
    then null
    else
      {
        hooks = renderedHooks;
      }
      // lib.optionalAttrs (groupDef ? matcher) {inherit (groupDef) matcher;};

  renderEvents = target:
    lib.filterAttrs (_: groups: groups != []) (
      lib.mapAttrs (
        _: groups:
          builtins.filter (groupDef: groupDef != null) (map (renderGroup target) groups)
      )
      events
    );
in {
  inherit events;

  claude = renderEvents "claude";
  codex = renderEvents "codex";

  # OpenCode's JSON schema does not expose native lifecycle hooks.
  opencode = {};
}
