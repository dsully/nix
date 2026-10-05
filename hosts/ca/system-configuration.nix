{flake, ...}: {
  imports = [
    flake.modules.system-manager.beszel-agent
    flake.modules.system-manager.common
    ./options.nix
  ];

  config = {
    services.beszel-agent = {
      enable = true;
      listen = "100.65.20.65:45876"; # Tailscale
    };

    # Binding fails until tailscale0 has its address; Restart=always retries.
    systemd.services.beszel-agent.after = ["tailscaled.service"];
  };
}
