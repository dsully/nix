{
  flake,
  pkgs,
  ...
}: {
  imports = [
    flake.modules.system-manager.common
    flake.modules.system-manager.caddy
    ./options.nix
  ];

  config = {
    services.caddy = {
      enable = true;
      caddyfile = ./files/Caddyfile;
    };

    environment = {
      systemPackages = with pkgs; [
        fish
        system-manager
      ];
    };
  };
}
