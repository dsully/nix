{mkSystemManagerHost}:
mkSystemManagerHost {
  hostName = "tnt";
  home = false;

  extraModules = [
    {
      modules.system.beszel-agent = {
        enable = true;
        listen = "100.95.41.16:45876"; # Tailscale
      };
    }
  ];
}
