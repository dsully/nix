{
  flake,
  perSystem,
  pkgs,
  ...
}: {
  imports = [
    flake.homeModules.dsully
    flake.homeModules.ai
    ../options.nix
  ];

  home = {
    packages = with pkgs;
      [
        bacon
        copilot-language-server
        ghostscript_headless
        nix-output-monitor
        pandoc
        tectonic-unwrapped

        (caddy.withPlugins
          {
            plugins = [
              "github.com/caddy-dns/cloudflare@v0.2.2-0.20250506153119-35fb8474f57d"
              "github.com/caddy-dns/linode@v0.8.0"
              "github.com/abiosoft/caddy-inspect@v0.0.0-20250214103948-96cdb1dfb122"
            ];
            hash = "sha256-p9ZPtN7SewWNlUHClxnnsqi8OIFqydWb3Smg/qjxEgU=";
          })
      ]
      ++ (with perSystem.self; [
        autorebase
        zuban
      ]);
  };
}
