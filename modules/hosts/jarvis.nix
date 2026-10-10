{mkDarwinHost}:
mkDarwinHost {
  hostName = "jarvis";

  userConfig = {
    ssh.opnixKey.enable = true;
    paste.enable = true;
    pi.enable = true;
    rumdl.enable = true;
    unifi.enable = true;
    xdg-open-svc.enable = true;

    opencode.enable = false;
  };

  extraModules = [
    ./jarvis/homebrew.nix
    ./jarvis/system.nix
  ];

  extraHomeModules = [./jarvis/dsully.nix];
}
