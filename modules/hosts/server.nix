{mkSystemManagerHost}:
mkSystemManagerHost {
  hostName = "server";

  userConfig = {
    ssh.opnixKey.enable = true;
    cachix.enable = true;
    copypaste.enable = true;
    pi.enable = true;
    rex.enable = true;
    rumdl.enable = true;
    unifi.enable = true;
  };

  extraModules = [
    ./server/containers.nix
    ./server/system.nix
  ];

  extraHomeModules = [
    ./server/dsully.nix
    ./server/rex.nix
  ];

  # root@server: activate with `just switch-root`.
  extraHomeUsers.root.userConfig = {
    ai.enable = true;
    core-shell.enable = true;
  };
}
