{mkDarwinHost}:
mkDarwinHost {
  hostName = "jarvis";

  userConfig = {
    gortex.enable = true;
    paste.enable = true;
    pi.enable = true;
    rex.enable = true;
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
