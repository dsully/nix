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
              # "github.com/caddy-dns/linode@b63fbb996d391e0668ce1174a2ca68ccac63201f"
              "github.com/abiosoft/caddy-inspect@v0.0.0-20250214103948-96cdb1dfb122"
            ];
            hash = "sha256-5HCHGxAk8pskatPMvpBiCXRMQcfjZ9o8ATfEVL7mDWE=";
          })
      ]
      ++ (with perSystem.self; [
        autorebase
        zuban
      ]);
  };
}
