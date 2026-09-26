{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.zoned;
  homeDir = config.home.homeDirectory;
in {
  options.programs.zoned.enable = lib.mkEnableOption "zoned Cloudflare dynamic DNS updater";

  config = lib.mkIf cfg.enable {
    home.activation.zonedConfig = inputs.home-manager.lib.hm.dag.entryAfter ["writeBoundary" "onepassword-secrets"] ''
      token_file="${homeDir}/.config/zoned/cloudflare-token"
      zone_file="${homeDir}/.config/zoned/cloudflare-zone-id"

      if [ -f "$token_file" ] && [ -f "$zone_file" ]; then
        cat > "${homeDir}/.config/zoned/config.toml" <<TOML
      hostname = "${config.system.hostName}.sully.org"
      ${lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''ssid = "sully"''}
      token = "$(cat "$token_file")"
      zoneid = "$(cat "$zone_file")"
      TOML
        chmod 600 "${homeDir}/.config/zoned/config.toml"
      fi
    '';

    programs.onepassword-secrets.secrets = {
      zonedCloudflareToken = {
        reference = "op://Services/Cloudflare DNS Token/credential";
        path = ".config/zoned/cloudflare-token";
        mode = "0600";
        group = config.system.primaryGroup;
      };
      zonedCloudflareZoneId = {
        reference = "op://Services/Cloudflare DNS Token/zoneid";
        path = ".config/zoned/cloudflare-zone-id";
        mode = "0600";
        group = config.system.primaryGroup;
      };
    };
  };
}
