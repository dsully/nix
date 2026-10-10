{mkSystemManagerHost}:
mkSystemManagerHost {
  hostName = "ca";
  home = false;

  extraModules = [
    {
      modules.system.beszel-agent = {
        enable = true;
        listen = "100.65.20.65:45876"; # Tailscale
      };
    }
  ];
}
