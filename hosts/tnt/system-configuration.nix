{flake, ...}: {
  imports = [
    flake.modules.system-manager.beszel-agent
    flake.modules.system-manager.common
    flake.modules.system-manager.tailscale
    ./options.nix
  ];

  config = {
    services = {
      beszel-agent = {
        enable = true;
        listen = "100.95.41.16:45876"; # Tailscale
      };

      tailscale = {
        enable = true;
        setFlags = ["--accept-dns=true" "--accept-routes=false" "--advertise-exit-node" "--exit-node-allow-lan-access=true" "--ssh=false"];
      };
    };

    # Binding fails until tailscale0 has its address; Restart=always retries.
    systemd.services.beszel-agent.after = ["tailscaled.service"];
  };
}
