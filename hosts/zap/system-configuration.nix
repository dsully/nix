{
  flake,
  pkgs,
  ...
}: {
  imports = [
    flake.modules.system-manager.beszel-agent
    flake.modules.system-manager.common
    flake.modules.system-manager.tailscale
    flake.modules.system-manager.caddy
    ./options.nix
  ];

  config = {
    services = {
      # zap is public; accept the hub only over the tailnet.
      beszel-agent = {
        enable = true;
        listen = "100.127.204.51:45876";
      };

      caddy = {
        enable = true;
        caddyfile = ./files/Caddyfile;
      };

      tailscale = {
        enable = true;
        setFlags = ["--accept-dns=false" "--accept-routes=true" "--advertise-exit-node" "--ssh=true"];
      };
    };
    # Binding fails until tailscale0 has its address; Restart=always retries.
    systemd.services.beszel-agent.after = ["tailscaled.service"];

    environment = {
      systemPackages = with pkgs; [
        fish
        system-manager
      ];
    };
  };
}
