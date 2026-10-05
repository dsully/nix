{flake, ...}: {
  imports = [
    flake.modules.system-manager.beszel-agent
    flake.modules.system-manager.common
    ./options.nix
  ];

  config = {
    services.beszel-agent = {
      enable = true;
      listen = "100.95.41.16:45876"; # Tailscale
    };

    # Binding fails until tailscale0 has its address; Restart=always retries.
    systemd.services.beszel-agent.after = ["tailscaled.service"];
  };
}
