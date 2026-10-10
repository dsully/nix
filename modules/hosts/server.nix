{mkSystemManagerHost}:
mkSystemManagerHost {
  hostName = "server";

  userConfig = {
    ssh.opnixKey.enable = true;
    cachix.enable = true;
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
