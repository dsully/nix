{
  ai,
  config,
  lib,
  pkgs,
  wrapperLib,
  ...
}: let
  cfg = config.programs.omp;

  jsonFormat = pkgs.formats.json {};
  yamlFormat = pkgs.formats.yaml {};

  configFile = yamlFormat.generate "omp-config.yml" cfg.settings;

  # omp joins PI_CONFIG_DIR onto $HOME, so the value is a home-relative path and
  # not an absolute one. It moves the whole root (agent dir, plugins, run, logs,
  # install-id), because omp never reads XDG_CONFIG_HOME itself. The XDG data,
  # state, and cache roots below then pull everything except the config back out
  # of ~/.config. See `packages/utils/src/dirs.ts` in oh-my-pi.
  ompConfigDir = "${lib.removePrefix "${config.home.homeDirectory}/" config.xdg.configHome}/omp";
  ompPath = "${config.xdg.configHome}/omp/agent";

  # omp redirects data/state/cache to $XDG_<kind>_HOME/omp only when that
  # directory already exists (this is all `omp config init-xdg` does), and it
  # checks on every start, so the roots are created before the config is written.
  xdgRoots = [
    "${config.xdg.cacheHome}/omp"
    "${config.xdg.dataHome}/omp"
    "${config.xdg.stateHome}/omp"
  ];

  # The session variable alone is not enough: a shell that never sources
  # hm-session-vars.sh (a launchd job, a `login -f`, an editor terminal) would
  # fall back to ~/.omp, which no longer exists, and omp dies acquiring the
  # config lock. Bake the value into the binary so every entry point agrees.
  # `--set-default` keeps an explicit PI_CONFIG_DIR (a second checkout, a test
  # root) working.
  # pname, version, and meta (including mainProgram) carry over from `package`.
  # `pkgs` is explicit because nix-wrapper-modules evaluates the wrapper against
  # a whole package set (same reason as packages/nh.nix).
  ompPackage = wrapperLib.wrapPackage {
    inherit pkgs;
    inherit (cfg) package;

    # `envDefault`, so an explicit PI_CONFIG_DIR still wins.
    envDefault.PI_CONFIG_DIR = ompConfigDir;
  };

  # omp expands `${VAR}` and `${VAR:-default}` in discovered MCP configs. The
  # typed schema emits the `{env:VAR}` form, so rewrite it.
  rewriteEnvPlaceholders = lib.replaceStrings ["{env:"] ["\${"];
  rewriteMcpValue = value:
    if builtins.isString value
    then rewriteEnvPlaceholders value
    else if builtins.isAttrs value
    then lib.mapAttrs (_: rewriteMcpValue) value
    else if builtins.isList value
    then map rewriteMcpValue value
    else value;

  # Force every MCP server on regardless of its declared `enabled`/`disabled`.
  # transformMcpServer resolves the flag first, then folds extraTransforms over
  # the attrs, so this runs last and wins; the trailing null/empty filter then
  # keeps `enabled = true` (a resolved `null` would otherwise be dropped).
  forceEnableMcpServer = server: server // {enabled = true;};

  # Normalize via lib.hm.mcp.transformMcpServer to drop the typed schema's null
  # and empty-default fields. `addType` writes the explicit `stdio`/`http`
  # transport tag that omp validates against `command`/`url`.
  ompMcpServer = server:
    lib.hm.mcp.transformMcpServer {
      inherit server;
      extraTransforms = [
        lib.hm.mcp.addType
        rewriteMcpValue
        forceEnableMcpServer
      ];
    };

  ompMcpServers = lib.mapAttrs (_: ompMcpServer) config.programs.mcp.servers;

  # One file per marketplace agent, the omp counterpart of
  # `programs.opencode.agents`. omp resolves an agent by its frontmatter `name`,
  # so the attribute key only names the file.
  agentFiles =
    lib.mapAttrs' (name: text: {
      name = "${ompPath}/agents/${name}.md";
      value.text = text;
    })
    ai.ompAgents;

  # Slash commands, the omp counterpart of `programs.opencode.commands`. omp
  # reads the same Claude markdown shape (frontmatter `description`, `$ARGUMENTS`
  # and `$1`-style placeholders) and takes the command name from the filename.
  commandFiles =
    lib.mapAttrs' (name: text: {
      name = "${ompPath}/commands/${name}.md";
      value.text = text;
    })
    ai.commands;

  # omp auto-detects a built-in server when its root markers are in the cwd and
  # its binary resolves, so bashls, gopls, nil, rust-analyzer, and
  # typescript-native need no config: home installs each binary on PATH. Only the
  # two servers omp has no built-in entry for are declared here, and a config
  # merges onto the defaults rather than replacing them, so auto-detection of
  # every other server is unaffected.
  #
  # Both need the three required fields. emmylua-ls is not a rename of the
  # built-in `lua-language-server` entry, whose `settings.Lua` block is written
  # for that other binary; the built-in never starts anyway, because
  # lua-language-server is not installed.
  ompLspServers = {
    emmylua-ls = {
      inherit (ai.lsp.lua) command;
      fileTypes = [".lua"];
      rootMarkers = [
        ".emmyrc.json"
        ".luarc.json"
        ".luarc.jsonc"
        ".stylua.toml"
        "stylua.toml"
      ];
    };

    tombi = {
      inherit (ai.lsp.toml) command args;
      fileTypes = [".toml"];
      rootMarkers = [
        "tombi.toml"
        "Cargo.toml"
        "pyproject.toml"
        ".git"
      ];
    };
  };
in {
  imports = [
    ./omp/theme.nix
    ./omp/plugins.nix
  ];

  # Merged copy of oh-my-pi's own home-manager module (nix/home-manager.nix).
  # Upstream takes the omp flake as `{ self }` and defaults `package` to
  # `self.packages.<system>.default`; this flake has no oh-my-pi input, so the
  # default comes from the `llm-agents` input instead.
  options.programs.omp = {
    enable = lib.mkEnableOption "OMP coding agent";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.llm-agents.omp;
      defaultText = lib.literalExpression "pkgs.llm-agents.omp";
      description = "OMP package to install.";
    };

    settings = lib.mkOption {
      type = lib.types.nullOr yamlFormat.type;
      default = null;
      description = ''
        Settings written declaratively to {file}`~/.omp/agent/config.yml`.
        On each `home-manager switch` the declared settings are copied into
        place as a writable regular file (not a read-only store symlink), so
        OMP can acquire its config lock and rewrite the file when persisting
        runtime changes (`/settings`, onboarding). Those runtime changes are
        overwritten by the declared values again on the next
        `home-manager switch`.
      '';
      example = {
        theme.dark = "titanium";
        startup.quiet = true;
      };
    };
  };

  config = lib.mkMerge [
    {programs.omp.enable = lib.mkDefault true;}

    (lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = lib.hasPrefix "${config.home.homeDirectory}/" config.xdg.configHome;
          message = "programs.omp: omp resolves PI_CONFIG_DIR under $HOME, so xdg.configHome must be inside ${config.home.homeDirectory}.";
        }
      ];

      home = {
        packages = [ompPackage];

        # OMP rewrites its config at runtime and acquires an advisory lock on it
        # first; on macOS the lock backend creates an flock sidecar next to the
        # target file. A `home.file` store symlink is read-only and lives under
        # /nix/store, so both the lock and the atomic rewrite fail with EACCES
        # and break every launch. Copy a writable regular file instead.
        activation.ompConfig = lib.mkIf (cfg.settings != null) (
          lib.hm.dag.entryAfter ["writeBoundary"] ''
            run mkdir -p ${lib.escapeShellArgs ([ompPath] ++ xdgRoots)}
            run install -m 600 ${configFile} "${ompPath}/config.yml"
          ''
        );

        sessionVariables.PI_CONFIG_DIR = ompConfigDir;

        file =
          agentFiles
          // commandFiles
          // {
            "${ompPath}/mcp.json" = lib.mkIf (ompMcpServers != {}) {
              source = jsonFormat.generate "omp-mcp.json" {
                mcpServers = ompMcpServers;
              };
            };

            "${ompPath}/lsp.json".source = jsonFormat.generate "omp-lsp.json" {
              servers = ompLspServers;
            };

            # Native user context file. It has the highest discovery priority, so
            # it shadows ~/.claude/CLAUDE.md and every other user-level context file.
            "${ompPath}/AGENTS.md".text = ''
              ${builtins.readFile ./AGENTS.md}
              ${ai.rulesMarkdown}
            '';
          };
      };

      programs = {
        # omp reads native user skills from ~/.omp/agent/skills. The built-in
        # agent-skills targets do not cover that path, so declare it here.
        agent-skills.targets.omp = {
          dest = "${ompPath}/skills";
          structure = "symlink-tree";
        };

        omp.settings = {
          setupVersion = 2;

          astGrep.enabled = true;
          autolearn.enabled = true;
          commands.enableClaudeUser = false;
          composer.shape = "pi";
          defaultThinkingLevel = ai.models.large.reasoning_effort;
          dev.autoqa = false;
          display.showTokenUsage = false;

          edit = {
            autoRepair.enabled = true;
            mode = "hashline";
          };

          error.notify = "on";
          extendedContext = true;
          hideThinkingBlock = true;
          lsp.formatOnWrite = true;

          marketplace.autoUpdate = "off";
          memory.backend = "off";

          modelRoles = {
            default = "${ai.models.large.provider}/${ai.models.large.model}";
            plan = "${ai.models.large.provider}/${ai.models.large-high.model}";
            commit = "${ai.models.large.provider}/${ai.models.small.model}";
            smol = "${ai.models.large.provider}/${ai.models.small.model}";
          };

          personality = "pragmatic";
          providers.memoryModel = "qwen3-1.7b";

          retry.waitForUsageReset = true;

          skills = {
            enableSkillCommands = false;
            enableClaudeUser = false;
          };

          spelling.typoDetection = false;

          startup = {
            changelogMode = "hidden";
            checkUpdate = false;
            quiet = true;
            setupWizard = false;
          };

          statusLine = {
            preset = "custom";
            separator = "powerline-thin";
            sessionAccent = false;
            transparent = true;

            # Mirror opencode's layout: model + path on the left, context on the
            # right alongside the session's live counters.
            leftSegments = [
              "model"
              "path"
              "git"
            ];

            rightSegments = [
              "context_pct"
              "subagents"
              "time_spent"
            ];

            segmentOptions = {
              git = {
                showBranch = true;
                showStaged = false;
                showUnstaged = false;
                showUntracked = false;
              };

              model.showThinkingLevel = true;
            };
          };

          steeringMode = "one-at-a-time";
          symbolPreset = "nerd";
          terminal.showProgress = true;

          theme = {
            dark = "nord";
            light = "light";
          };

          tools.approvalMode = "yolo";

          tui = {
            textSizing = true;
            reactions = false;
          };
        };
      };
    })
  ];
}
