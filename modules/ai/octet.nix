{
  mkUserModule,
  ai,
  config,
  lib,
  my,
  pkgs,
  wrapperLib,
  ...
}: let
  octetDir = "${config.home.homeDirectory}/.octet";
  piPath = config.programs.pi-coding-agent.configDir;

  # octet-pi-compat comes from packages/octet-pi-compat (patched), the rest from octet's catalog.
  catalogExtensions = [
    "octet-codemode"
    "octet-mcp"
    "octet-subagents"
  ];

  piCompat = my.pkgs.octet-pi-compat;
  piRelease = my.pkgs.pi-release;

  octet = wrapperLib.wrapPackage {
    inherit pkgs;
    package = my.pkgs.octet;
    drv.name = "${my.pkgs.octet.name}-wrapped";
    envDefault.OCTET_PI_AGENT_DIR = piPath;
  };

  piTheme = config.programs.pi-coding-agent.settings.theme;

  # octet's native loader rejects the whole theme over pi-bolt's extra mdCodeBlockBg token.
  octetTheme = pkgs.runCommand "octet-${piTheme}.json" {nativeBuildInputs = [pkgs.jq];} ''
    jq 'del(.colors.mdCodeBlockBg)' ${config.home.file."${piPath}/themes/${piTheme}.json".source} > $out
  '';

  configToml = (pkgs.formats.toml {}).generate "octet-config.toml" {
    model = "codex/gpt-6-sol";
    reasoning = ai.models.large.reasoning_effort;
    theme = piTheme;
    enabled_extensions = catalogExtensions ++ ["octet-pi-compat"];
  };

  keybindingsJson = (pkgs.formats.json {}).generate "octet-keybindings.json" {
    "app.exit" = ["ctrl+d" "ctrl+z"];
  };

  # octet-mcp is stdio-only by default and rejects IDs outside [a-z][a-z0-9-]{0,31}.
  mcpJson = (pkgs.formats.json {}).generate "octet-mcp.json" {
    version = 1;
    servers =
      lib.mapAttrs (name: server: {
        transport = "stdio";
        label = name;
        inherit (server) command;
        args = lib.optionals (server.args != null) server.args;
        env = lib.optionalAttrs (server.env != null) server.env;
        enabled = server.enabled != false;
        required = false;
      })
      (lib.filterAttrs (name: server: server.command != null && builtins.match "[a-z][a-z0-9-]{0,31}" name != null)
        config.programs.mcp.servers);
  };
in
  mkUserModule {
    name = "octet";
    default = false;
    requires = ["pi"];
    needs = ["ai"];

    home = {
      home = {
        packages = [octet];

        # octet-pi-compat runs Pi-owned provider streams from this managed release; pi-bolt ignores install/.
        file = {
          "${piPath}/install/current-version".text = "${piRelease.version}\n";
          "${piPath}/install/releases/${piRelease.version}".source = piRelease;
        };

        # octet refuses symlinked config files, so these are real copies.
        # Skills, AGENTS.md and keybindings reach octet through the pi-compat mirror.
        activation.octetConfig = lib.hm.dag.entryAfter ["piPatchExtensions"] ''
          export PATH="${pkgs.jq}/bin:$PATH"
          _octet=${octet}/bin/octet

          run mkdir -p ${octetDir}
          run install -m600 ${configToml} ${octetDir}/config.toml
          run install -m600 ${mcpJson} ${octetDir}/mcp.json
          run install -m644 ${keybindingsJson} ${octetDir}/keybindings.json
          run install -D -m644 ${octetTheme} ${octetDir}/themes/${piTheme}.json

          # Bundles pin the exact host version, so follow the installed octet.
          _version=$($_octet --version | cut -d' ' -f2)
          for _ext in ${lib.escapeShellArgs catalogExtensions}; do
            _manifest=${octetDir}/extensions/$_ext/install.json
            if [[ ! -f $_manifest ]]; then
              run $_octet extension install "$_ext" || echo "octet extension install $_ext failed"
            elif [[ $(jq -r .version "$_manifest") != "$_version" ]]; then
              run $_octet extension update "$_ext" || echo "octet extension update $_ext failed"
            fi
          done

          _manifest=${octetDir}/extensions/octet-pi-compat/install.json
          if [[ ! -f $_manifest ]]; then
            run $_octet extension install --path ${piCompat} || echo "octet-pi-compat install failed"
          elif [[ $(jq -r .source "$_manifest") != ${piCompat} ]]; then
            run $_octet extension update --path ${piCompat} || echo "octet-pi-compat update failed"
          fi
        '';
      };
    };
  }
