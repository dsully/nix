{mkDarwinHost}:
mkDarwinHost {
  hostName = "jarvis";

  userConfig = {
    paste.enable = true;
    pi.enable = true;
    rumdl.enable = true;
    ssh.opnixKey.enable = true;
    unifi.enable = true;
    xdg-open-svc.enable = true;
  };

  extraModules = [
    ./jarvis/homebrew.nix
    ./jarvis/system.nix
  ];

  extraHomeModules = [./jarvis/dsully.nix];
}
