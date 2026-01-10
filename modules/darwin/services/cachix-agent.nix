{pkgs, ...}: let
  cacheName = "dsully";
  rawTokenPath = "/usr/local/var/opnix/secrets/cachixAuthToken";
  credentialsFile = "/etc/cachix-agent.token";
in {
  services.onepassword-secrets = {
    enable = true;
    secrets.cachixAuthToken.reference = "op://Services/Cachix/token";
  };

  launchd.daemons.cachix-watch-store = {
    script = ''
      . ${credentialsFile}
      exec ${pkgs.cachix}/bin/cachix watch-store ${cacheName}
    '';

    path = [pkgs.cachix];

    environment = {
      NIX_SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      USER = "root";
    };

    serviceConfig = {
      KeepAlive = true;
      RunAtLoad = true;
      ProcessType = "Interactive";
      StandardErrorPath = "/var/log/cachix-watch-store.log";
      StandardOutPath = "/var/log/cachix-watch-store.log";
      WatchPaths = [credentialsFile];
    };
  };

  system.activationScripts.cachix-watch-store-token = {
    deps = ["retrieveOpnixSecrets"];
    text = ''
      if [ -f "${rawTokenPath}" ]; then
        echo "export CACHIX_AUTH_TOKEN=$(cat ${rawTokenPath})" > ${credentialsFile}
        chmod 600 ${credentialsFile}
      fi
    '';
  };
}
