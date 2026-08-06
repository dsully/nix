{
  config,
  lib,
  my,
  pkgs,
  ...
}: let
  cfg = config.programs.llmtrim;
  claudeCodeCfg = cfg.integrations.claudeCode;

  # LLMTRIM_HOME would move this, but nothing else here needs it relocated.
  # ca.pem is llmtrim's own CA; ca-bundle.pem is that CA appended to the system
  # trust store (measured: 124 system certs + 1). Note `llmtrim ca` writes only
  # ca.pem — `setup --env` is what produces the bundle. See the activation
  # script below.
  stateDir = "${config.home.homeDirectory}/.llmtrim";
  caBundle = "${stateDir}/ca-bundle.pem";

  # `serve` always binds 127.0.0.1 and exposes no --host flag. The listener is
  # plain HTTP: clients CONNECT over loopback and llmtrim terminates the TLS
  # inside the tunnel, which is what the CA is for.
  proxyUrl = "http://127.0.0.1:${toString cfg.port}";

  # Verbatim from `llmtrim setup --env`, but scoped to the wrapped agents rather
  # than exported into the login shell. Interception is at the TLS layer, so
  # there is no per-agent knob like headroom's ANTHROPIC_BASE_URL — the only way
  # to bound it is to bound which processes see these. Exporting them globally
  # would route every HTTPS client on the machine through the proxy and swap its
  # trust store for llmtrim's snapshot bundle.
  #
  # `fd00::/8` is deliberately omitted: httpx's URLPattern proxy-map parser
  # accepts IPv4 CIDRs and bare/bracketed IPv6 addresses but rejects IPv6 *CIDR*
  # notation, raising `InvalidURL: Invalid port: ':'` at Client init. That
  # crashes any httpx-based MCP server that honors HTTPS_PROXY (e.g. FastMCP
  # startup version check hits the proxy). Unique-local IPv6 traffic to the loopback
  # proxy is not a real path here.
  noProxy = "localhost,127.0.0.1,::1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,169.254.0.0/16,*.local";

  environment = {
    HTTPS_PROXY = proxyUrl;
    HTTP_PROXY = proxyUrl;
    NO_PROXY = noProxy;
    no_proxy = noProxy;
    # `setup --env` points Node at the bare ca.pem, which leaves Node on its
    # built-in Mozilla roots plus llmtrim's CA. Use the bundle instead so hosts
    # whose roots are only in the system store (corporate CAs) keep verifying;
    # Node appends this to its built-ins, and the bundle is a superset of ca.pem.
    NODE_EXTRA_CA_CERTS = caBundle;
    NODE_USE_ENV_PROXY = "1";
    SSL_CERT_FILE = caBundle;
    CURL_CA_BUNDLE = caBundle;
  };

  llmtrimBin = lib.getExe my.pkgs.llmtrim;

  tomlFormat = pkgs.formats.toml {};

  # Wraps an agent so its process tree — the agent and any MCP server or
  # subprocess it spawns — routes through the interceptor, leaving the rest of
  # the session untouched. Call sites gate this on programs.llmtrim.enable.
  # `--set` rather than `--set-default`: a stale HTTPS_PROXY inherited from the
  # shell would otherwise silently send the agent somewhere else.
  llmtrimWrap = mainProgram: pkg:
    pkgs.symlinkJoin {
      name = "${lib.getName pkg}-llmtrim";
      # symlinkJoin's name carries no version, so `lib.getVersion` on the wrapper
      # would return "". Home Manager's claude-code module version-gates on that
      # and falls back to the legacy `--plugin-dir` wrapper when it can't tell.
      version = lib.getVersion pkg;
      paths = [pkg];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/${mainProgram} \
          ${lib.concatStringsSep " \\\n  " (
          lib.mapAttrsToList (k: v: "--set ${k} ${lib.escapeShellArg v}") environment
        )}
      '';
      # Preserved so `lib.getExe` and the agent modules keep resolving.
      meta = (pkg.meta or {}) // {inherit mainProgram;};
    };
in {
  options.programs.llmtrim = {
    enable = lib.mkEnableOption "llmtrim LLM payload-compressing HTTPS interceptor";

    port = lib.mkOption {
      type = lib.types.port;
      default = 43117;
      description = "Loopback port for the llmtrim interceptor to listen on.";
    };

    settings = lib.mkOption {
      inherit (tomlFormat) type;
      default = {};
      example = {
        preset = "aggressive";
        exclude_hosts = ["openrouter.ai"];
      };
      description = ''
        Contents of `$XDG_CONFIG_HOME/llmtrim/config.toml`. `preset` defaults to
        llmtrim's own `auto`; see the upstream README for per-stage flags.
      '';
    };

    # Everything `llmtrim setup`/`ensure` would write into ~/.claude/settings.json.
    # We never run those (this repo owns settings.json declaratively), so these
    # toggles drive the equivalent home-manager wiring instead.
    integrations.claudeCode = {
      statusLine = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Use `llmtrim statusline` as Claude Code's status line. Mutually
          exclusive with ccstatusline — Claude Code allows only one command.
        '';
      };

      guard = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Install llmtrim's cold-cache `UserPromptSubmit` guard hook.";
      };

      compactModels = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = ["haiku" "sonnet"];
        description = ''
          Ordered cheaper models tried for `/compact` once the prompt cache has
          gone cold. Claude Code's selected model is always the implicit final
          fallback, so do not list it. Empty records an explicit opt-out.
        '';
      };
    };
  };

  config = lib.mkMerge [
    # Exposed outside the `enable` guard so the arg always resolves; call sites
    # apply it only when programs.llmtrim.enable is set.
    {_module.args.llmtrimWrap = llmtrimWrap;}

    (lib.mkIf cfg.enable (
      lib.mkMerge [
        {
          assertions = [
            {
              assertion = !config.programs.headroom.enable;
              message = "programs.llmtrim and programs.headroom both proxy Anthropic traffic; enable at most one.";
            }
            {
              assertion = !config.programs.rtk.enable;
              message = "programs.llmtrim and programs.rtk both compress agent payloads; enable at most one.";
            }
            {
              assertion = !(claudeCodeCfg.statusLine || claudeCodeCfg.guard) || config.programs.claude-code.enable;
              message = "programs.llmtrim.integrations.claudeCode.{statusLine,guard} require programs.claude-code.enable.";
            }
          ];

          xdg.configFile."llmtrim/config.toml".source = tomlFormat.generate "llmtrim-config.toml" (
            cfg.settings // {compact.models = claudeCodeCfg.compactModels;}
          );

          home = {
            packages = [my.pkgs.llmtrim];
          };
        }

        # `llmtrim doctor` and the `status` health chain decide whether the proxy
        # env is wired by scanning the shell profiles it knows about for the first
        # literal `127.0.0.1:<port>` substring (setup.rs `configured_port_in` ->
        # `parse_proxy_port`). It is a byte match with no shell parsing, so a
        # comment satisfies it. That is exactly what we want here: the real env
        # stays scoped to the wrapped agents (see `environment` above), while this
        # marker keeps both commands from reporting "env not wired". Caveat: it
        # also makes them report "degraded" rather than "stopped" when the daemon
        # is down, since they now believe a live shell env points at a dead port.
        (lib.mkIf config.programs.fish.enable {
          programs.fish.shellInit = lib.mkAfter ''
            # llmtrim: marker only, deliberately inert — the interceptor env is set
            # per-agent by llmtrimWrap, not exported into the login shell.
            # ${proxyUrl}
          '';
        })

        (lib.mkIf pkgs.stdenv.isLinux {
          systemd.user.services.llmtrim = {
            Unit = {
              Description = "llmtrim LLM payload-compressing HTTPS interceptor";
              After = ["network-online.target"];
            };
            Install.WantedBy = ["default.target"];
            Service = {
              # `--supervised` makes `serve` write ~/.llmtrim/serve.pid; without it
              # `doctor`/`status` see the listener but report "not running /
              # degraded — no pidfile" because their ownership check keys off that
              # file. `--port` pins the listener to the configured port.
              ExecStart = ["${llmtrimBin}" "serve" "--port" (toString cfg.port) "--supervised"];
              Restart = "on-failure";
              RestartSec = 5;
            };
          };
        })

        (lib.mkIf pkgs.stdenv.isDarwin {
          launchd.agents.llmtrim = {
            enable = true;
            waitForNixStore = false;
            config = {
              # `--supervised` makes `serve` write ~/.llmtrim/serve.pid so
              # `doctor`/`status` can confirm daemon ownership; bare `serve`
              # leaves them reporting "not running" despite a live listener.
              ProgramArguments = ["${llmtrimBin}" "serve" "--port" (toString cfg.port) "--supervised"];
              KeepAlive = {
                Crashed = true;
                SuccessfulExit = false;
              };
              ProcessType = "Background";
              RunAtLoad = true;
              ThrottleInterval = 5;
            };
            domain = lib.mkDefault "gui";
          };
        })
      ]
    ))
  ];
}
