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
      setFlags = ["--accept-dns=true" "--accept-routes=true" "--advertise-exit-node" "--ssh=true"];
    };

    # zap is public; accept the hub only over the tailnet.
    beszel-agent = {
      enable = true;
      listen = "100.127.204.51:45876";
    };
  };

  # eth0 gets no DNS from the network; tailscaled adds 100.100.100.100 on tailscale0 itself.
  environment.etc."systemd/resolved.conf.d/upstream.conf".text = ''
    [Resolve]
    DNS=96.126.122.5 198.58.111.5 23.239.24.5
    FallbackDNS=1.1.1.1#cloudflare-dns.com 1.0.0.1#cloudflare-dns.com 2606:4700:4700::1111#cloudflare-dns.com 2606:4700:4700::1001#cloudflare-dns.com
  '';
}
