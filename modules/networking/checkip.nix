{
  mkUserModule,
  config,
  inputs,
  pkgs,
  ...
}: let
  homeDir = config.home.homeDirectory;
in
  mkUserModule {
    name = "checkip";
    default = false;

    home = {
      home = {
        packages = [pkgs.checkip];

        activation.checkipConfig = inputs.home-manager.lib.hm.dag.entryAfter ["writeBoundary" "onepassword-secrets"] ''
          maxmind_key="${homeDir}/.config/checkip/maxmind-key"
          urlscan_key="${homeDir}/.config/checkip/urlscan-key"

          if [ -f "$maxmind_key" ] && [ -f "$urlscan_key" ]; then
            cat > "${homeDir}/.checkip.yaml" <<YAML
          ---
          MAXMIND_LICENSE_KEY: $(cat "$maxmind_key")
          URLSCAN_API_KEY: $(cat "$urlscan_key")
          YAML
            chmod 600 "${homeDir}/.checkip.yaml"
          fi
        '';
      };

      programs.onepassword-secrets.secrets = {
        checkipMaxmind = {
          reference = "op://Services/MaxMind API/credential";
          path = ".config/checkip/maxmind-key";
        };
        checkipUrlscan = {
          reference = "op://Services/URLScan API/credential";
          path = ".config/checkip/urlscan-key";
        };
      };
    };
  }
