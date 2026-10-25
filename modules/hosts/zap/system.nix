_: {
  modules.system = {
    caddy = {
      enable = true;
      caddyfile = ./files/Caddyfile;
      visualizer = {
        enable = true;
        listen = "100.127.204.51";
      };
    };

    tailscale = {
      enable = true;
      setFlags = ["--accept-dns=false" "--accept-routes=true" "--advertise-exit-node" "--ssh=true"];
    };

    # zap is public; accept the hub only over the tailnet.
    beszel-agent = {
      enable = true;
      listen = "100.127.204.51:45876";
    };
  };
}
