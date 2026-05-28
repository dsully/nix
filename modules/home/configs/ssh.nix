{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.home) homeDirectory;
  inherit (config.system) hostName;

  withRemoteForwards = block:
    block
    // {
      RemoteForward = map (port: {
        bind = {inherit port;};
        host = {
          address = "localhost";
          inherit port;
        };
      }) (lib.range 2224 2226);
    };

  # Tailscale CLI lives in different places depending on how it was installed.
  # On jarvis it's the `tailscale-app` cask; on the Linux server it's a daemon
  # package. Either way an absolute path is needed because `Match exec` runs
  # via /bin/sh with a stripped environment.
  tailscaleBin =
    if pkgs.stdenv.hostPlatform.isDarwin
    then "/Applications/Tailscale.app/Contents/MacOS/Tailscale"
    else "${pkgs.tailscale}/bin/tailscale";

  # Exits 0 iff tailscaled is up AND the named peer is currently online.
  # Matches on DNSName prefix (e.g. "gateway") rather than the peer's OS
  # HostName, because the two don't always coincide -- the UDM advertises
  # itself as "udm-pro" but its tailnet DNS name is "gateway.<tailnet>".
  tsPeerOnline = pkgs.writeShellScript "ssh-ts-peer-online" ''
    ${tailscaleBin} status --json 2>/dev/null \
      | ${pkgs.jq}/bin/jq -e --arg h "$1" \
          'any(.Peer[]?; (.DNSName | startswith($h + ".")) and .Online == true)' \
          >/dev/null
  '';

  # The single LAN whose direct addresses are preferable to the tailscale
  # overlay: the home network. Any peer whose `lan` field starts with this
  # prefix gets an "am I sitting on it right now?" guard wrapped around the
  # tailscale override. A different 10.x or 192.168.x network elsewhere will
  # not match, so the override still fires when away from home.
  homeLanPrefix = "10.0.0.";

  # Exits 0 iff this host currently has an IPv4 address on the home LAN.
  # `ifconfig` (darwin) and `ip addr` (linux) both emit the literal
  # substring "inet <addr>", so a single grep handles both.
  ifaceCmd =
    if pkgs.stdenv.hostPlatform.isDarwin
    then "/sbin/ifconfig"
    else "${pkgs.iproute2}/bin/ip addr";
  onHomeLan = pkgs.writeShellScript "ssh-on-home-lan" ''
    ${ifaceCmd} 2>/dev/null | grep -q "inet ${homeLanPrefix}"
  '';

  # Match-exec body: peer online AND (when the peer is itself a home-LAN host)
  # I'm not currently on that LAN.
  tsExec = name: lanIp:
    if lib.hasPrefix homeLanPrefix lanIp
    then ''! ${onHomeLan} && ${tsPeerOnline} ${name}''
    else "${tsPeerOnline} ${name}";

  muxOff = {
    ControlMaster = "no";
    ControlPersist = "no";
  };

  # Hosts reachable on both a non-tailscale address (LAN or public) and
  # via MagicDNS. The Host block sets the default; a sibling Match block
  # overrides HostName to the ts.net name when tailscaled is up.
  dual = {
    zap = {
      lan = "172.104.194.233";
      ts = "zap.tail2ca1.ts.net";
      forward = true;
      noMux = false;
    };
    ca = {
      lan = "192.46.222.69";
      ts = "ca.tail2ca1.ts.net";
      forward = false;
      noMux = true;
    };
    tnt = {
      lan = "172.236.14.101";
      ts = "tnt.tail2ca1.ts.net";
      forward = false;
      noMux = true;
    };
    server = {
      lan = "10.0.0.100";
      ts = "server.tail2ca1.ts.net";
      forward = true;
      noMux = false;
    };
  };

  mkHost = _: s: let
    base = {HostName = s.lan;} // lib.optionalAttrs s.noMux muxOff;
  in
    if s.forward
    then withRemoteForwards base
    else base;

  mkTsMatch = name: s: {
    header = ''Match originalhost ${name} exec "${tsExec name s.lan}"'';
    HostName = s.ts;
  };

  # Attr-key prefix `0-` ensures these emit before any Host block in the
  # generated ~/.ssh/config (home-manager sorts blocks alphabetically by attr
  # key). Required because ssh_config uses first-value-wins per option, so a
  # Match override must appear before its corresponding Host block.
  tsMatches = lib.mapAttrs' (n: s: lib.nameValuePair "0-ts-${n}" (mkTsMatch n s)) dual;

  publicDual = lib.filterAttrs (n: _: n != "server") dual;
  jarvisDual = {inherit (dual) server;};
  publicTsMatches = lib.filterAttrs (n: _: n != "0-ts-server") tsMatches;
  jarvisTsMatches = {"0-ts-server" = tsMatches."0-ts-server";};
in {
  programs.ssh = {
    enable = true;

    enableDefaultConfig = false;

    settings = lib.mkMerge [
      ({
          "*" = {
            AddKeysToAgent = "yes";
            Compression = true;
            ControlMaster = "auto";
            ControlPath = "~/.ssh/sockets/%r@%h-%p";
            ControlPersist = "10m";
            ForwardAgent = lib.mkDefault true;
            ServerAliveInterval = 10;
            IdentityAgent = "SSH_AUTH_SOCK";
            UseKeychain = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin "yes";
            SendEnv = "COLORTERM TERM_PROGRAM TERM_PROGRAM_VERSION";
            SetEnv = {
              SSH_CLIENT_HOME = homeDirectory;
              SSH_CLIENT_MOUNT = "/Volumes";
              SSH_CLIENT_OS = "Darwin";
            };
          };

          "github.com" = {
            User = "git";
            HostName = "github.com.";
            IdentitiesOnly = true;
            ControlMaster = "no";
            ControlPersist = "no";
          };
        }
        // (lib.mapAttrs mkHost publicDual)
        // publicTsMatches)

      (lib.mkIf (hostName != "friday") {
        "sisyphus" = {
          HostName = "10.0.0.135";
          User = "pi";
        };

        "unifi gateway 10.0.0.1" = {
          HostName = "10.0.0.1";
          User = "root";
          IdentityFile = "${homeDirectory}/.ssh/id_rsa";
          LocalForward = [
            {
              bind.port = 27017;
              host.address = "127.0.0.1";
              host.port = 27117;
            }
          ];
        };

        "0-ts-gateway" = {
          header = ''Match originalhost gateway exec "${tsExec "gateway" "10.0.0.1"}"'';
          HostName = "gateway.tail2ca1.ts.net";
        };

        "nvr" = {
          User = "root";
          HostName = "10.0.0.2";
          IdentityFile = "${homeDirectory}/.ssh/id_rsa";
        };

        "switch" = {
          HostName = "10.0.0.3";
          User = "ubnt";
          IdentityFile = "${homeDirectory}/.ssh/id_rsa";
        };
      })

      (lib.mkIf (hostName != "jarvis") {
        "jarvis" = {
          HostName = "10.0.0.97";
        };
      })

      (lib.mkIf (hostName == "jarvis") (
        {
          "travel" = {
            HostName = "192.168.8.1";
            User = "root";
          };

          "work" = {
            HostName = "10.0.0.95";
          };
        }
        // (lib.mapAttrs mkHost jarvisDual)
        // jarvisTsMatches
      ))
    ];
  };
}
