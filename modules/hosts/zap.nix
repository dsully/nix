{
  mkSystemManagerHost,
  users,
}:
mkSystemManagerHost {
  hostName = "zap";
  primaryUser = users.dsully;
  users = [users.dsully];

  userConfig.dsully = {
    copypaste.enable = true;

    ai.enable = false;
    ccstatusline.enable = false;
    claude-code.enable = false;
    herdr.enable = false;
    mcp-mux.enable = false;
    opencode.enable = false;
    skills.enable = false;
  };

  extraModules = [./zap/system.nix];
  extraHomeModules = [./zap/dsully.nix];
}
