{
  mkSystemManagerHost,
  users,
}:
mkSystemManagerHost {
  hostName = "server";
  primaryUser = users.dsully;
  users = [users.dsully];

  userConfig.dsully = {
    copypaste.enable = true;
    pi.enable = true;
    rumdl.enable = true;
    unifi.enable = true;
  };

  extraModules = [
    ./server/containers.nix
    ./server/system.nix
  ];

  extraHomeModules = [./server/dsully.nix];
}
