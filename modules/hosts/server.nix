{mkSystemManagerHost}:
mkSystemManagerHost {
  hostName = "server";

  userConfig = {
    ssh.opnixKey.enable = true;
    cachix.enable = true;
    copypaste.enable = true;
    pi.enable = true;
    rex.enable = false;
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
    btop.enable = true;
    delta.enable = true;
    direnv.enable = true;
    dotfiles.enable = true;
    editor.enable = true;
    fd.enable = true;
    fish.enable = true;
    fzf.enable = true;
    git.enable = true;
    home-base.enable = true;
    lla.enable = true;
    pager.enable = true;
    procs.enable = true;
    ripgrep.enable = true;
    system-tools.enable = true;
    vivid.enable = true;
    zoxide.enable = true;
  };
}
