{mkSystemManagerHost}:
mkSystemManagerHost {
  hostName = "zap";

  userConfig = {
    copypaste.enable = true;

    ai.enable = false;
  };

  extraModules = [./zap/system.nix];
}
