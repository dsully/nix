{
  config,
  lib,
}: let
  taxonomy = {
    shell = {
      wrappers = lib.optional config.programs.rtk.enable "rtk";

      askCommands = [
        "rm"
        "rmdir"
      ];

      denyCommands = [
        "git"
        "su"
        "sudo"
      ];

      readOnly = [
        ["awk"]
        ["basename"]
        ["cargo"]
        ["cat"]
        ["command" "-v"]
        ["curl"]
        ["cut"]
        ["df"]
        ["dirname"]
        ["dmesg"]
        ["du"]
        ["fd"]
        ["file"]
        ["find"]
        ["gh" "issue" ["view" "list"]]
        ["gh" "pr" ["view" "list" "diff" "checks"]]
        ["gh" "repo" "view"]
        ["gh" "run" ["view" "list"]]
        ["git" "blame"]
        ["git" "branch"]
        ["git" "diff"]
        ["git" "grep"]
        ["git" "log"]
        ["git" "ls-files"]
        ["git" "ls-tree"]
        ["git" "reflog"]
        ["git" "remote"]
        ["git" "rev-parse"]
        ["git" "show"]
        ["git" "status"]
        ["git" "submodule" "status"]
        ["grep"]
        ["head"]
        ["home-manager"]
        ["journalctl"]
        ["jq"]
        ["just"]
        ["ls"]
        ["nh" "search"]
        ["nix" ["build" "eval" "path-info"]]
        ["nix" "flake" "metadata"]
        ["nix" "flake" "show"]
        ["ps"]
        ["pwd"]
        ["readlink"]
        ["realpath"]
        ["rg"]
        ["sed" "-n"]
        ["sort"]
        ["stat"]
        ["systemctl" "list-timers"]
        ["systemctl" "list-units"]
        ["systemctl" "status"]
        ["tail"]
        ["uname"]
        ["uniq"]
        ["wc"]
      ];
    };

    read = {
      allow = [
        "${config.xdg.configHome}/claude/skills/**"
        "${config.home.homeDirectory}/dev/**"
        "${config.home.homeDirectory}/src/**"
        "/tmp/**"
      ];
      ask = [
        "./secrets/**"
      ];
      deny = [
        config.xdg.cacheHome
        "${config.home.homeDirectory}/.cargo"
        "${config.home.homeDirectory}/.ssh"
        "./build"
        "./config/credentials.json"
        "./.direnv"
        "./.env"
        "./.env.*"
        "*.env"
        "*.env.*"
        "./.envrc"
        "./target"
      ];
    };

    edit = {
      allow = [
        "**/*.md"
        "/tmp/**"
        "**/plans/**"
      ];
      ask = [];
      deny = [
        "*.env"
        "*.env.*"
      ];
    };

    directory = {
      allow = [
        "${config.home.homeDirectory}/dev"
        "${config.home.homeDirectory}/src"
        "/tmp"
        "/var"
      ];
    };

    tool = {
      allow = [
        "Glob"
        "Grep"
        "WebFetch"
        "WebSearch"
      ];
      ask = [];
      deny = [];
    };

    skill = {
      allow = [
        "ast-grep"
      ];
      ask = [];
      deny = [];
    };

    mcp = {
      autoAllowServers = true;
    };
  };

  inherit (taxonomy) shell;

  claudeExactShell = command: "Bash(${command})";
  claudePath = tool: path: "${tool}(${path})";
  claudeSkill = skill: "Skill(${skill})";

  shellPrefixAlternatives = prefix:
    lib.foldr (
      part: suffixes: let
        alternatives =
          if builtins.isList part
          then part
          else [part];
      in
        lib.concatMap (
          alternative: map (suffix: [alternative] ++ suffix) suffixes
        )
        alternatives
    ) [[]]
    prefix;

  shellPrefixString = prefix:
    lib.concatStringsSep " " prefix;

  claudeShellPrefix = prefix: "Bash(${prefix} *)";

  codexAtom = atom:
    if builtins.isList atom
    then "[${lib.concatMapStringsSep ", " codexAtom atom}]"
    else builtins.toJSON atom;

  codexPrefixRule = decision: pattern: "prefix_rule(pattern = ${codexAtom pattern}, decision = \"${decision}\")";

  opencodeAskShell = command: "${command}*";
  opencodeDenyShell = command: "${command} *";

  attrsWithDecision = decision: values:
    lib.listToAttrs (map (value: lib.nameValuePair value decision) values);

  wrappedAllowPrefixes = lib.concatMap (
    wrapper: map (prefix: [wrapper] ++ prefix) shell.readOnly
  ) (shell.wrappers or []);

  allowPrefixes = shell.readOnly ++ wrappedAllowPrefixes;
  expandedAllowPrefixes = lib.concatMap shellPrefixAlternatives allowPrefixes;
  allowPrefixStrings = lib.unique (map shellPrefixString expandedAllowPrefixes);

  # Codex does not expand placeholders in MCP headers; it reads the token from
  # the environment via bearer_token_env_var instead. Convert any http server
  # whose Authorization header is `Bearer {env:NAME}` into that native form,
  # dropping the header so Codex receives a token it can actually send.
  codexBearerEnvVar = server: let
    match = builtins.match "Bearer [{]env:([A-Za-z_][A-Za-z0-9_]*)[}]" (server.headers.Authorization or "");
  in
    if match == null
    then null
    else builtins.head match;

  # The Codex module replaces its generated mcp_servers entry with the one in
  # settings.mcp_servers per server name (a shallow `//`), so this must emit a
  # complete entry. Mirror the module's lib.hm.mcp.transformMcpServer normalization
  # (drop `headers`/`type`, resolve `enabled`, filter nulls/empty defaults), then
  # add the auto-approve flag and rewrite Bearer auth into Codex's native form.
  codexMcpServerAutoApprove = server: let
    envVar = codexBearerEnvVar server;
    remainingHeaders = lib.removeAttrs server.headers ["Authorization"];
  in
    lib.hm.mcp.transformMcpServer {
      inherit server;
      exclude = ["headers" "type"];
      extraTransforms = [
        (s:
          if envVar == null
          then s // lib.optionalAttrs (s.headers != {}) {http_headers = s.headers;}
          else
            s
            // {bearer_token_env_var = envVar;}
            // lib.optionalAttrs (remainingHeaders != {}) {http_headers = remainingHeaders;})
        (s: s // {default_tools_approval_mode = "approve";})
      ];
    };

  opencodeShellPermissions =
    attrsWithDecision "allow" (map (prefix: "${prefix} *") allowPrefixStrings)
    // attrsWithDecision "ask" (map opencodeAskShell shell.askCommands)
    // attrsWithDecision "deny" (
      map opencodeDenyShell (lib.remove "git" shell.denyCommands)
    );

  opencodePathPermissions = rules:
    attrsWithDecision "allow" rules.allow
    // attrsWithDecision "ask" rules.ask
    // attrsWithDecision "deny" rules.deny;
in rec {
  inherit taxonomy;

  claude = {
    permissions = {
      allow =
        (map claudeShellPrefix allowPrefixStrings)
        ++ (map (claudePath "Edit") taxonomy.edit.allow)
        ++ taxonomy.tool.allow
        ++ (map (claudePath "Read") taxonomy.read.allow)
        ++ (map claudeSkill taxonomy.skill.allow)
        # Claude rejects a server-position glob (mcp__*); enumerate each
        # configured server as mcp__<name> to auto-allow all of its tools.
        ++ lib.optionals taxonomy.mcp.autoAllowServers (
          map (name: "mcp__${name}") (lib.attrNames config.programs.mcp.servers)
        );

      ask =
        (map claudeExactShell shell.askCommands)
        ++ (map (claudePath "Read") taxonomy.read.ask);

      deny =
        (map claudeExactShell shell.denyCommands)
        ++ (map (claudePath "Read") taxonomy.read.deny);

      additionalDirectories = taxonomy.directory.allow;
      defaultMode = "auto";
      disableBypassPermissionsMode = "disable";
    };

    skipAutoPermissionPrompt = true;
  };

  codex = {
    mcpServers = lib.mapAttrs (_: codexMcpServerAutoApprove);

    rules.common = ''
      # Generated from ai.permissions.taxonomy.shell.*Prefixes. Codex prefix
      # rules cover shell execution only; read/edit/tool policy is enforced by
      # its sandbox and by the other agents' native permission systems.
      ${lib.concatStringsSep "\n" (map (codexPrefixRule "allow") expandedAllowPrefixes)}
    '';
  };

  opencode = {
    permission = {
      bash = opencodeShellPermissions;
      edit = opencodePathPermissions taxonomy.edit;
      external_directory = {
        "/**" = "allow";
      };
      lsp = "allow";
      read = opencodePathPermissions taxonomy.read;
      webfetch = "allow";
    };
  };
}
