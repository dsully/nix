{
  lib,
  pkgs,
  ...
}: let
  secrets = [
    "bridge_pin"
    "dyson_credentials"
    "ecobee_refresh_token"
    "pushover_token"
    "pushover_user"
    "weather_apikey"
  ];

  secretFile = name: "/var/lib/opnix/homebridge-${name}";
  secret = name: assert lib.elem name secrets; "op-secret:${name}";

  hbService = "/usr/lib/node_modules/homebridge-config-ui-x/dist/bin/hb-service.js";

  # Prints only the paths that differ, never values: secrets live in both files.
  driftFilter = pkgs.writeText "homebridge-drift.jq" ''
    $old[0] as $o
    | $new[0] as $n
    | [($o, $n) | paths(if type == "object" or type == "array" then length == 0 else true end)]
    | unique[]
    | . as $p
    | select((try ($o | getpath($p)) catch "<type changed>") != (try ($n | getpath($p)) catch "<type changed>"))
    | "config.json drifted from homebridge.nix at "
      + (map(if type == "number" then "[\(.)]" else ".\(.)" end) | add)
  '';

  # Substitutes each "op-secret:<name>" string with its opnix file.
  renderConfig =
    pkgs.writeShellScript "homebridge-config"
    # bash
    ''
      set -euo pipefail
      umask 077

      out=/var/lib/homebridge/config.json

      ${lib.getExe pkgs.jq} \
        ${lib.concatMapStringsSep " " (n: "--rawfile ${n} ${secretFile n}") secrets} \
        'walk(if type == "string" and startswith("op-secret:") then $ARGS.named[ltrimstr("op-secret:")] // error("no secret for \(.)") else . end)' \
        ${(pkgs.formats.json {}).generate "homebridge-config.json" settings} > "$out.tmp"

      if [ -e "$out" ]; then
        ${lib.getExe pkgs.jq} -rn --slurpfile old "$out" --slurpfile new "$out.tmp" -f ${driftFilter} >&2 \
          || echo "config.json drift check failed; overwriting anyway" >&2
      fi

      chown homebridge:homebridge "$out.tmp"
      chmod 0640 "$out.tmp"

      mv "$out.tmp" "$out"
    '';

  # UI edits are overwritten on the next start; the journal lists the drifted paths.
  settings = {
    accessories = [
      {
        _bridge = {
          port = 32620;
          username = "0E:A2:E7:E7:A2:FD";
        };
        accessory = "HomebridgeMessenger";
        messages = [
          {
            name = "Outdoor Fridge Alert";
            priority = 0;
            sound = "pushover";
            text = "Temperature Too High";
            type = "pushover";
          }
        ];
        name = "Messenger";
        services = {
          email = {smtpPort = 8080;};
          pushover = {
            token = secret "pushover_token";
            user = secret "pushover_user";
          };
        };
      }
      {
        _bridge = {
          port = 39415;
          username = "0E:4F:20:12:A1:25";
        };
        accessory = "virtual-presence";
        name = "Dan Arrives";
        switches = ["Dan Present"];
      }
      {
        _bridge = {
          port = 32621;
          username = "0E:A2:E7:E7:A5:FD";
        };
        accessory = "virtual-presence";
        name = "Karine Arrives";
        switches = ["Karine Present"];
      }
      {
        _bridge = {
          port = 41089;
          username = "0E:A2:A6:1B:20:E6";
        };
        accessory = "virtual-presence";
        name = "Olivia Arrives";
        switches = ["Olivia Present"];
      }
      {
        _bridge = {
          port = 58238;
          username = "0E:9C:9C:BC:27:FC";
        };
        accessory = "virtual-presence";
        name = "Eliza Arrives";
        switches = ["Eliza Present"];
      }
    ];
    bridge = {
      advertiser = "avahi";
      bind = ["eth0"];
      name = "Homebridge";
      pin = secret "bridge_pin";
      port = 51826;
      username = "CC:22:3D:E3:CE:32";
    };
    description = "HomeBridge";
    disabledPlugins = ["homebridge-ecobee-away"];
    platforms = [
      {
        auth = "none";
        lang = "auto";
        name = "Config";
        platform = "config";
        port = 8581;
        proxyHost = "homebridge.sully.org";
        tempUnits = "f";
        theme = "blue-grey";
      }
      {
        _bridge = {
          port = 31850;
          username = "0E:9A:43:8A:9F:34";
        };
        devices = [
          {
            buttons = [
              {
                displayType = 0;
                namePrefix = false;
                reference = "0PWON";
              }
            ];
            buttonsZ2 = [
              {
                displayType = 0;
                namePrefix = false;
                reference = "1ON";
              }
            ];
            buttonsZ3 = [
              {
                displayType = 0;
                namePrefix = false;
                reference = "1ON";
              }
            ];
            disableLogDeviceInfo = true;
            disableLogError = false;
            disableLogInfo = true;
            disableLogSuccess = false;
            disableLogWarn = false;
            enableDebugMode = false;
            generation = 1;
            getFavoritesFromDevice = false;
            getInputsFromDevice = false;
            getQuickSmartSelectFromDevice = false;
            host = "10.0.0.77";
            infoButtonCommand = "MNMEN ON";
            inputs = [
              {
                name = "TV Audio";
                reference = "TV";
              }
              {
                name = "AirPlay";
                reference = "NET";
              }
            ];
            inputsDisplayOrder = 1;
            mqtt = {
              auth = false;
              debug = false;
              enable = false;
            };
            name = "Denon";
            passThroughInputs = [{reference = "SAT/CBL";}];
            port = 8080;
            powerControlZone = 0;
            refreshInterval = 5;
            restFul = {
              debug = false;
              enable = false;
            };
            sensorInput = false;
            sensorInputs = [
              {
                displayType = 0;
                namePrefix = false;
                reference = "SAT/CBL";
              }
            ];
            sensorMute = false;
            sensorPower = true;
            sensorSurrounds = [
              {
                displayType = 0;
                namePrefix = false;
                reference = "STEREO";
              }
            ];
            sensorVolume = false;
            surrounds = [{reference = "STEREO";}];
            volumeControlNamePrefix = false;
            volumeControlType = 3;
            volumeControlZone = 0;
            volumeMax = 100;
            zoneControl = 0;
          }
        ];
        platform = "DenonTv";
      }
      {
        _bridge = {
          port = 32738;
          username = "0E:D3:0A:36:2D:B1";
        };
        apikey = secret "weather_apikey";
        cityIds = [5382514];
        dailyForecasts = 1;
        locations = [];
        name = "Weather";
        platform = "WS";
      }
      {
        _bridge = {
          port = 55397;
          username = "0E:D6:64:64:C6:D4";
        };
        name = "Ecobee Away";
        platform = "EcobeeAway";
        refreshToken = secret "ecobee_refresh_token";
        thermostatSerialNumbers = "531620837803, 531686631755";
      }
      {
        _bridge = {
          port = 30581;
          username = "0E:E1:08:D6:BE:8B";
        };
        accessories = [
          {
            disableLogging = false;
            id = "1246d959-f021-4c56-9bf2-3c84ded37508";
            name = "Vacation Sentinel";
            type = "Switch";
          }
          {
            defaultOn = 0;
            id = "934e8aa8-6d00-4aaf-8445-9577b40b008e";
            name = "Dummy Lock";
            type = "Switch";
          }
        ];
        name = "Homebridge Dummy";
        platform = "HomebridgeDummy";
      }
      {
        _bridge = {
          port = 52908;
          username = "0E:9D:65:28:1C:C9";
        };
        devices = [
          {
            credentials = secret "dyson_credentials";
            enableAutoModeWhenActivating = false;
            enableNightModeWhenActivating = false;
            enableOscillationWhenActivating = false;
            humidityOffset = 0;
            ipAddress = "10.0.20.186";
            isAirQualityIgnored = false;
            isAirQualitySensorEnabled = false;
            isAutoModeEnabled = false;
            isContinuousMonitoringEnabled = false;
            isFullRangeHumidity = false;
            isHeatingDisabled = false;
            isHeatingSafetyIgnored = false;
            isHumidityIgnored = false;
            isHumiditySensorEnabled = false;
            isJetFocusEnabled = false;
            isNightModeEnabled = false;
            isSingleAccessoryModeEnabled = false;
            isSingleSensorAccessoryModeEnabled = false;
            isTemperatureIgnored = false;
            isTemperatureSensorEnabled = false;
            serialNumber = "C2A-US-MMA5117B";
            temperatureOffset = 0;
            useFahrenheit = false;
          }
        ];
        platform = "DysonPureCoolPlatform";
      }
    ];
  };
in {
  modules.system.opnix.secrets =
    map (name: {
      path = secretFile name;
      reference = "op://Services/Homebridge/${name}";
    })
    secrets;

  environment.etc = lib.mapAttrs (_: v: v // {replaceExisting = true;}) {
    "default/homebridge".source = ./files/homebridge.default;
    "sudoers.d/homebridge".source = ./files/sudoers-homebridge;
  };

  systemd.services.homebridge = {
    enable = true;
    description = "Homebridge";
    wantedBy = ["system-manager.target"];
    wants = ["network-online.target"];
    requires = ["opnix-secrets.service"];
    after = ["syslog.target" "network-online.target" "opnix-secrets.service"];
    partOf = ["avahi-daemon.service"];
    serviceConfig = {
      Type = "simple";
      User = "homebridge";
      PermissionsStartOnly = true;
      WorkingDirectory = "/var/lib/homebridge";
      EnvironmentFile = "/etc/default/homebridge";
      ExecStartPre = [
        "+${renderConfig}"
        "-/bin/run-parts /etc/hb-service/homebridge/prestart.d"
        "-${hbService} before-start $HOMEBRIDGE_OPTS"
      ];
      ExecStart = "${hbService} run $HOMEBRIDGE_OPTS";
      Restart = "always";
      RestartSec = 3;
      KillMode = "process";
      CapabilityBoundingSet = [
        "CAP_IPC_LOCK"
        "CAP_NET_ADMIN"
        "CAP_NET_BIND_SERVICE"
        "CAP_NET_RAW"
        "CAP_SETGID"
        "CAP_SETUID"
        "CAP_SYS_CHROOT"
        "CAP_CHOWN"
        "CAP_FOWNER"
        "CAP_DAC_OVERRIDE"
        "CAP_AUDIT_WRITE"
        "CAP_SYS_ADMIN"
      ];
      AmbientCapabilities = ["CAP_NET_RAW" "CAP_NET_BIND_SERVICE"];
      Environment = [
        "PATH=/var/lib/homebridge/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin"
        "NPM_CONFIG_PREFIX=/usr"
      ];
    };
  };
}
