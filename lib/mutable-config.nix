let
  mkMutableConfig = {
    defaultMergeExpr,
    extension,
    format,
    initContent,
    mergeCommand,
    validateCommand,
  }: {
    name,
    target,
    managed,
    mode ? "0600",
    mergeExpr ? defaultMergeExpr,
  }: {
    config,
    lib,
    pkgs,
    ...
  }: let
    managedFile = (pkgs.formats.${format} {}).generate "${name}-managed.${extension}" managed;
    cfg = "${config.xdg.configHome}/${lib.removePrefix "/" target}";
  in {
    home.activation."merge-${name}-${format}" = lib.hm.dag.entryAfter ["writeBoundary"] ''
      set -euo pipefail
      umask 077
      dir="$(dirname "${cfg}")"
      mkdir -p "$dir"

      if [ ! -e "${cfg}" ]; then
        printf '%s' ${lib.escapeShellArg initContent} > "${cfg}"
      fi

      if ! ${validateCommand pkgs lib} "${cfg}" > /dev/null 2>&1; then
        cp -f "${cfg}" "${cfg}.bak.$(date +%s)" || true
        printf '%s' ${lib.escapeShellArg initContent} > "${cfg}"
      fi

      tmp="$(mktemp "$dir/.${name}.${extension}.XXXXXX")"
      trap 'rm -f "$tmp"' EXIT
      ${mergeCommand pkgs lib mergeExpr} "${cfg}" ${managedFile} > "$tmp"
      chmod ${mode} "$tmp"
      mv -f "$tmp" "${cfg}"
      trap - EXIT
    '';
  };
in {
  json = mkMutableConfig {
    defaultMergeExpr = ".[0] * .[1]";
    extension = "json";
    format = "json";
    initContent = "{}";
    mergeCommand = pkgs: lib: mergeExpr: "${lib.getExe pkgs.jq} -s ${lib.escapeShellArg mergeExpr}";
    validateCommand = pkgs: lib: "${lib.getExe pkgs.jq} -e .";
  };

  yaml = mkMutableConfig {
    defaultMergeExpr = ". as $item ireduce ({}; . * $item)";
    extension = "yaml";
    format = "yaml";
    initContent = "{}";
    mergeCommand = pkgs: lib: mergeExpr: "${lib.getExe pkgs.yq-go} -p yaml -o yaml eval-all ${lib.escapeShellArg mergeExpr}";
    validateCommand = pkgs: lib: "${lib.getExe pkgs.yq-go} -p yaml -e .";
  };

  toml = mkMutableConfig {
    defaultMergeExpr = ". as $item ireduce ({}; . * $item)";
    extension = "toml";
    format = "toml";
    initContent = "";
    mergeCommand = pkgs: lib: mergeExpr: "${lib.getExe pkgs.yq-go} -p toml -o toml eval-all ${lib.escapeShellArg mergeExpr}";
    validateCommand = pkgs: lib: "${lib.getExe pkgs.yq-go} -p toml -e .";
  };
}
