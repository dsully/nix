{
  config,
  lib,
  pkgs,
}: let
  command = attrs: attrs // {type = "command";};

  hook = {
    name,
    command,
    targets ? ["claude" "codex" "pi"],
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

  icmEnabled = config.programs.icm.enable or true;
  rtkEnabled = config.programs.rtk.enable;

  events = {
    PreCompact = lib.optional icmEnabled (group {
      hooks = [
        (hook {
          name = "icm-compact";
          command = "${lib.getExe pkgs.llm-agents.icm} hook compact";
        })
      ];
    });

    PreToolUse = [
      (group {
        matcher = "Read";
        hooks = [
          (hook {
            name = "prefer-indxr-before-read";
            command = ''
              echo 'IMPORTANT: Before reading full source files, use indxr MCP tools to minimize token usage:
              - summarize(path): understand a file without reading it (~300 tokens vs ~3000+)
              - find(query): find specific functions/types by name, concept, or signature
              - read(path, symbol): read only the exact function/symbol you need (~100 tokens vs full file)
              Only use Read when you need to EDIT a file, need exact formatting, or the file is not source code (e.g., CLAUDE.md, Cargo.toml).'
            '';
          })
        ];
      })
      (group {
        matcher = "Bash";
        hooks =
          [
            (hook {
              name = "prefer-indxr-diff-summary";
              command = ''
                if printf '%s' "$TOOL_INPUT" | grep -qE 'git\s+diff'; then
                  echo 'IMPORTANT: Use indxr get_diff_summary MCP tool instead of git diff (requires --all-tools). It shows structural changes (added/removed/modified declarations) at ~200-500 tokens vs thousands for raw diffs. Example: get_diff_summary(since_ref: "main")'
                fi
              '';
            })
            (hook {
              name = "enforce-uv";
              command = "${./hooks/enforce-uv.fish}";
            })
          ]
          ++ lib.optional rtkEnabled (hook {
            name = "rtk-rewrite";
            command = "${pkgs.llm-agents.rtk}/libexec/rtk/hooks/claude/rtk-rewrite.sh";
            targets = ["claude"];
          })
          ++ lib.optional icmEnabled (hook {
            name = "icm-pre";
            command = "${lib.getExe pkgs.llm-agents.icm} hook pre";
          });
      })
    ];

    PostToolUse =
      [
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
          ];
        })
      ]
      # icm extracts facts from *all* tool output every N calls, so it must not
      # be scoped to file-mutation tools. No matcher = fires on every tool.
      ++ lib.optional icmEnabled (group {
        hooks = [
          (hook {
            name = "icm-post";
            command = "${lib.getExe pkgs.llm-agents.icm} hook post";
          })
        ];
      });

    SessionStart = lib.optional icmEnabled (group {
      hooks = [
        (hook {
          name = "icm-start";
          command = "${lib.getExe pkgs.llm-agents.icm} hook start";
        })
      ];
    });

    UserPromptSubmit = lib.optional icmEnabled (group {
      hooks = [
        (hook {
          name = "icm-prompt";
          command = "${lib.getExe pkgs.llm-agents.icm} hook prompt";
        })
      ];
    });
  };

  supportsTarget = target: hookDef:
    builtins.elem target hookDef.targets
    && !(target == "pi" && lib.hasPrefix "icm-" hookDef.name);

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

  codexEventLabels = {
    PreToolUse = "pre_tool_use";
    PermissionRequest = "permission_request";
    PostToolUse = "post_tool_use";
    PreCompact = "pre_compact";
    PostCompact = "post_compact";
    SessionStart = "session_start";
    UserPromptSubmit = "user_prompt_submit";
    SubagentStart = "subagent_start";
    SubagentStop = "subagent_stop";
    Stop = "stop";
  };

  codexConfigFile = "${config.xdg.configHome}/codex/config.toml";

  codexHookHash = eventName: groupDef: hookDef: let
    matcher = groupDef.matcher or null;
    eventLabel = codexEventLabels.${eventName};
    normalizedHook =
      {
        type = "command";
        inherit (hookDef) command;
        timeout = hookDef.timeout or 600;
        async = hookDef.async or false;
      }
      // lib.optionalAttrs (hookDef ? statusMessage) {
        inherit (hookDef) statusMessage;
      };
    normalizedIdentity =
      {
        event_name = eventLabel;
        hooks = [normalizedHook];
      }
      // lib.optionalAttrs (matcher != null) {inherit matcher;};
  in "sha256:${builtins.hashString "sha256" (builtins.toJSON normalizedIdentity)}";

  codexHookStateEntry = eventName: groupIndex: hookIndex: groupDef: hookDef:
    lib.nameValuePair
    "${codexConfigFile}:${codexEventLabels.${eventName}}:${toString groupIndex}:${toString hookIndex}"
    {trusted_hash = codexHookHash eventName groupDef hookDef;};

  codexHookStateForGroup = eventName: groupIndex: groupDef:
    lib.imap0 (
      hookIndex: hookDef:
        codexHookStateEntry eventName groupIndex hookIndex groupDef hookDef
    )
    groupDef.hooks;

  codexHookStateForEvent = eventName: groups:
    lib.flatten (
      lib.imap0 (
        groupIndex: groupDef:
          codexHookStateForGroup eventName groupIndex groupDef
      )
      groups
    );

  renderCodex = let
    renderedEvents = renderEvents "codex";
    stateEntries = lib.flatten (
      lib.mapAttrsToList codexHookStateForEvent renderedEvents
    );
  in
    renderedEvents
    // {
      state = builtins.listToAttrs stateEntries;
    };
in {
  inherit events;

  claude = renderEvents "claude";
  codex = renderCodex;
  pi = renderEvents "pi";

  # OpenCode's JSON schema does not expose native lifecycle hooks.
  opencode = {};
}
