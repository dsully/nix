# hosts/server/containers.nix
#
# Each entry becomes a `docker-<name>` systemd unit.
_: {
  local.docker = {
    enable = true;

    # Merged into every container; TZ is the same host-wide.
    defaultEnvironment.TZ = "US/Pacific";

    containers = {
      backblaze = {
        image = "docker.io/tessypowder/backblaze-personal-wine:latest";
        extraOptions = ["--init"];
        ports = [
          "5901:5900"
          "8082:5800"
        ];
        environment = {
          GROUP_ID = "0";
          LANG = "en_US.UTF-8";
          SECURE_CONNECTION = "0";
          USER_ID = "0";
          VNC_PASSWORD = "password";
        };
        volumes = [
          "/opt/docker/backblaze:/config"
          "/bits:/drive_d/"
          "/ai:/drive_e/"
        ];
      };

      bazaar = {
        image = "ghcr.io/hotio/bazarr:latest";
        extraOptions = ["--log-driver" "none"];
        ports = ["6767:6767"];
        environment = {
          PGID = "1000";
          PUID = "1000";
          UMASK = "002";
        };
        volumes = [
          "/opt/docker/bazaar:/config"
          "/bits/media/movies:/movies"
          "/bits/media/tv:/tv"
        ];
      };

      crashplan = {
        image = "docker.io/jlesage/crashplan-pro:latest";
        extraOptions = ["--network" "host"];
        environment = {
          CRASHPLAN_SRV_MAX_MEM = "16G";
          DISPLAY_HEIGHT = "1200";
          DISPLAY_WIDTH = "1920";
          GROUP_ID = "0";
          KEEP_APP_RUNNING = "1";
          USER_ID = "0";
        };
        volumes = [
          "/opt/docker/crashplan:/config:rw"
          "/:/storage:ro"
        ];
      };

      headless-shell = {
        image = "docker.io/chromedp/headless-shell:latest";
        extraOptions = [
          "--network"
          "host"
        ];
      };

      jellyseerr = {
        image = "fallenbagel/jellyseerr";
        ports = [
          "5055:5055"
        ];
        environment = {
          LOG_LEVEL = "error";
          PORT = "5055";
        };
        volumes = ["/opt/docker/jellyseerr:/app/config"];
      };

      network-optimizer = {
        image = "ghcr.io/ozark-connect/network-optimizer:latest";
        extraOptions = ["--network" "host"];
        environment = {
          BIND_LOCALHOST_ONLY = "false";
          HOST_NAME = "server.sully.org";
          Iperf3Server__Enabled = "false";
          Logging__LogLevel__Default = "Information";
          Logging__LogLevel__NetworkOptimizer = "Information";
          OPENSPEEDTEST_HTTPS = "false";
          OPENSPEEDTEST_HTTPS_PORT = "443";
          OPENSPEEDTEST_PORT = "3005";
        };
        volumes = [
          "/opt/docker/network-optimizer/data:/app/data"
          "/opt/docker/network-optimizer/ssh-keys:/app/ssh-keys:ro"
          "/opt/docker/network-optimizer/logs:/app/logs"
        ];
      };

      network-optimizer-speedtest = {
        image = "ghcr.io/ozark-connect/speedtest:latest";
        extraOptions = ["--log-opt" "max-size=10m" "--log-opt" "max-file=3"];
        ports = ["3005:3000"];
        environment = {
          HOST_NAME = "server.sully.org";
          OPENSPEEDTEST_HTTPS = "false";
          OPENSPEEDTEST_HTTPS_PORT = "443";
          OPENSPEEDTEST_PORT = "3005";
        };
      };

      portainer = {
        image = "portainer/portainer-ce:latest";
        ports = [
          "8000:8000"
          "9443:9443"
        ];
        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock"
          "/opt/docker/portainer:/data"
        ];
      };

      scrypted = {
        image = "docker.io/koush/scrypted:latest";
        extraOptions = [
          "--network"
          "host"
          "--log-driver"
          "none"
          "--device"
          "/dev/dri/card1"
        ];
        volumes = ["/opt/docker/scrypted/volume:/server/volume"];
      };
    };
  };
}
