{pkgs, ...}:
pkgs.caddy.withPlugins {
  plugins = [
    "github.com/caddy-dns/cloudflare@v0.2.2-0.20250506153119-35fb8474f57d"
    "github.com/caddy-dns/linode@v0.8.0"
    "github.com/abiosoft/caddy-inspect@v0.0.0-20250214103948-96cdb1dfb122"
    "github.com/abiosoft/caddy-json-schema@v0.0.0-20220621031927-c4d6e132f3af"
  ];
  hash = "sha256-NWixKSkpcbP+z4Do+1jrMXgEIE9BvMpQiSP7sGp0M5Q=";
}
