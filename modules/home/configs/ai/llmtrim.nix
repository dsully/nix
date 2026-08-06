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
  noProxy = "localhost,127.0.0.1,::1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,169.254.0.0/16,fd00::/8,*.local";

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

  # --force because `serve` refuses to start when another daemon already holds
  # the port; on a service restart a stale one would otherwise wedge it.
  serveArgs =
    [
      llmtrimBin
      "serve"
      "--port"
      (toString cfg.port)
      "--force"
    ]
    ++ cfg.extraArgs;

  # The daemon must not inherit `environment` — it *is* the proxy, so pointing
  # HTTPS_PROXY at itself would loop, and SSL_CERT_FILE would pin it to a bundle
  # it may not have generated yet.
  launchWrapper = pkgs.writeShellScript "llmtrim-serve-launch" ''
    set -eu
    exec ${lib.escapeShellArgs serveArgs}
  '';
in {
  options.programs.llmtrim = {
    enable = lib.mkEnableOption "llmtrim LLM payload-compressing HTTPS interceptor";

    port = lib.mkOption {
      type = lib.types.port;
      default = 43117;
      description = "Loopback port for the llmtrim interceptor to listen on.";
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Additional arguments passed to `llmtrim serve`.";
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
              assertion = !(claudeCodeCfg.statusLine || claudeCodeCfg.guard) || config.programs.claude-code.enable;
              message = "programs.llmtrim.integrations.claudeCode.{statusLine,guard} require programs.claude-code.enable.";
            }
          ];

          xdg.configFile."llmtrim/config.toml".source = tomlFormat.generate "llmtrim-config.toml" (
            cfg.settings // {compact.models = claudeCodeCfg.compactModels;}
          );

          home = {
            packages = [my.pkgs.llmtrim];

            # No sessionVariables: the interceptor env reaches agents through
            # `llmtrimWrap` only. Nothing else on the machine is proxied, and the
            # system trust store is left alone.

            # Both certs must exist before `serve` can intercept anything and
            # before any wrapped agent starts. `ca` alone writes only ca.pem;
            # `setup --env` also writes ca-bundle.pem and — verified against an
            # isolated HOME — touches nothing outside the state dir: no shell
            # profile, no autostart, no daemon. Idempotent.
            activation.llmtrimCA = lib.hm.dag.entryAfter ["writeBoundary" "installPackages"] ''
              run ${llmtrimBin} setup --env > /dev/null
            '';
          };
        }

        (lib.mkIf pkgs.stdenv.isLinux {
          systemd.user.services.llmtrim = {
            Unit = {
              Description = "llmtrim LLM payload-compressing HTTPS interceptor";
              After = ["network-online.target"];
            };
            Install.WantedBy = ["default.target"];
            Service = {
              ExecStart = "${launchWrapper}";
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
              ProgramArguments = ["${launchWrapper}"];
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
