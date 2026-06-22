# Bridge: ingest Claude Code marketplaces into the AI toolchain.
#
# Parses a marketplace's `.claude-plugin/marketplace.json`, then per plugin
# discovers skills (-> programs.agent-skills sources), agents (-> mkAI aiSources),
# and opencode plugins (-> programs.opencode settings.plugin, opt-in). For an
# opt-in set of MCP-free plugins it also emits Claude's native enablement
# (extraKnownMarketplaces + enabledPlugins), which is how Claude loads their
# hooks/commands. MCP servers (.mcp.json) are never ingested.
#
# A marketplace entry: {
#   name;                  # logical namespace (skill idPrefix + agent prefix)
#   src;                   # store path of the marketplace repo (e.g. inputs.foo)
#   input ? null;          # flake input NAME, when skills should resolve via input
#   pluginInputs ? {};     # "owner/repo" -> store path, for external plugin sources
#   opencodePlugins ? [];  # plugin names whose .opencode/plugins/* wire into opencode
#   claudeEnable ? [];     # plugin names to enable natively in claude (MCP-free only)
# }
{lib, ...}: let
  # Normalise a plugin `source` relative path: "./", ".", "" all mean repo root.
  relClean = src: let
    s = lib.removePrefix "./" src;
  in
    if s == "." || s == ""
    then ""
    else s;

  resolveRoot = mp: plugin: let
    src = plugin.source or null;
  in
    if builtins.isString src
    then let
      rel = relClean src;
    in
      if rel == ""
      then mp.src
      else "${mp.src}/${rel}"
    else if builtins.isAttrs src && builtins.hasAttr (src.repo or "") mp.pluginInputs
    then mp.pluginInputs.${src.repo}
    else null;

  # Top-level *.js / *.ts files under a plugin's .opencode/plugins directory.
  ocPluginFiles = root: let
    dir = "${root}/.opencode/plugins";
  in
    if builtins.pathExists dir
    then
      map (f: "${dir}/${f}") (
        builtins.attrNames (
          lib.filterAttrs (
            f: t:
              (t == "regular" || t == "symlink")
              && (lib.hasSuffix ".js" f || lib.hasSuffix ".ts" f)
          )
          (builtins.readDir dir)
        )
      )
    else [];

  discoverOne = mp: plugin: let
    name = plugin.name or (throw "marketplace ${mp.name}: plugin missing 'name'");
    root = resolveRoot mp plugin;
    rel =
      if builtins.isString (plugin.source or null)
      then relClean plugin.source
      else null;
    hasSkills = root != null && builtins.pathExists "${root}/skills";
    hasAgents = root != null && builtins.pathExists "${root}/agents";
    hasMcp = root != null && builtins.pathExists "${root}/.mcp.json";
  in
    if root == null
    then lib.warn "marketplace ${mp.name}: skipping plugin '${name}' (unsupported source)" null
    else {
      inherit name hasSkills hasMcp;
      claudeRequested = builtins.elem name mp.claudeEnable;

      skillSource = lib.optionalAttrs hasSkills {
        "${mp.name}-${name}" =
          if mp.input != null && rel != null
          then {
            input = mp.input;
            subdir =
              if rel == ""
              then "skills"
              else "${rel}/skills";
            idPrefix = mp.name;
          }
          else {
            path = "${root}/skills";
            idPrefix = mp.name;
          };
      };

      agentSource = lib.optionals hasAgents [
        {
          source = root;
          prefix = "${mp.name}-";
          agents = {include = ["*"];};
        }
      ];

      opencodePlugins = lib.optionals (builtins.elem name mp.opencodePlugins) (ocPluginFiles root);
    };

  withDefaults = mp:
    {
      input = null;
      pluginInputs = {};
      opencodePlugins = [];
      claudeEnable = [];
    }
    // mp;

  perMarketplace = mpRaw: let
    mp = withDefaults mpRaw;
    manifestPath = "${mp.src}/.claude-plugin/marketplace.json";
    manifest =
      if builtins.pathExists manifestPath
      then builtins.fromJSON (builtins.readFile manifestPath)
      else throw "marketplace ${mp.name}: no .claude-plugin/marketplace.json at ${manifestPath}";
    mpName = manifest.name or (throw "marketplace ${mp.name}: manifest missing 'name'");

    results = builtins.filter (x: x != null) (map (discoverOne mp) (manifest.plugins or []));
    claudeP = builtins.filter (r: r.claudeRequested) results;
    # No-MCP policy: a plugin enabled in Claude must not carry a .mcp.json.
    badMcp = builtins.filter (r: r.hasMcp) claudeP;
    # Claude loads an enabled plugin's skills natively, on top of the agent-skills
    # delivery to ~/.claude/skills, so skill-bearing claude plugins double up.
    dup = builtins.filter (r: r.hasSkills) claudeP;
  in
    if badMcp != []
    then throw "marketplace ${mp.name}: claudeEnable includes MCP-bearing plugins ${toString (map (r: r.name) badMcp)} (excluded by no-MCP policy)"
    else
      lib.warnIf (dup != [])
      "marketplace ${mp.name}: claude-enabled plugins ${toString (map (r: r.name) dup)} also ship skills; Claude will load them twice (native loader + agent-skills)"
      {
        skillSources = lib.foldl (a: r: a // r.skillSource) {} results;
        agentSources = lib.concatMap (r: r.agentSource) results;
        enableNames = map (r: "${mp.name}-${r.name}") (builtins.filter (r: r.skillSource != {}) results);
        opencodePlugins = lib.concatMap (r: r.opencodePlugins) results;
        claudeMarketplace = lib.optionalAttrs (claudeP != []) {
          ${mpName}.source = {
            source = "directory";
            path = mp.src;
          };
        };
        claudeEnabled = builtins.listToAttrs (
          map (r: lib.nameValuePair "${r.name}@${mpName}" true) claudeP
        );
      };
in {
  # marketplaces :: list of marketplace entries (see header). Returns the merged contributions for each downstream sink.
  mkMarketplace = marketplaces: let
    per = map perMarketplace marketplaces;
  in {
    skillSources = lib.foldl (a: p: a // p.skillSources) {} per;
    agentSources = lib.concatMap (p: p.agentSources) per;
    enableAll = lib.concatMap (p: p.enableNames) per;
    opencodePlugins = lib.concatMap (p: p.opencodePlugins) per;
    claudeMarketplaces = lib.foldl (a: p: a // p.claudeMarketplace) {} per;
    claudeEnabled = lib.foldl (a: p: a // p.claudeEnabled) {} per;
  };
}
