{
  config,
  flake,
  inputs,
  lib,
  pkgs,
  ...
}: let
  username = flake.lib.defaultUser;
in {
  imports = [
    inputs.nix-index-database.hmModules.nix-index
    ../common/nix.nix
    ../common/chsh

    ./packages
    ./bat.nix
    ./gh.nix
    ./git.nix
    ./lolcate.nix
    ./ssh.nix
  ];

  home = {
    # See here what bumping this value impacts:
    # https://nix-community.github.io/home-manager/release-notes.xhtml
    stateVersion = "25.05";

    activation = {
      chezmoi = inputs.home-manager.lib.hm.dag.entryAfter ["writeBoundary" "installPackages"] ''
        mkdir -p ~/.local/share

        if ! [ -d "$HOME/.local/share/chezmoi" ]; then
          ${lib.getExe pkgs.git} clone git@github.com:${username}/dotfiles.git ~/.local/share/chezmoi

          ${lib.getExe pkgs.chezmoi} init --apply --exclude encrypted ${username} < /dev/null
          ${lib.getExe pkgs.chezmoi} apply || true
        fi
      '';

      neovim = inputs.home-manager.lib.hm.dag.entryAfter ["writeBoundary" "installPackages"] ''

        if ! [ -d "$HOME/.config/nvim" ]; then
          ${lib.getExe pkgs.git} clone git@github.com:${username}/nvim.git ~/.config/nvim
        fi
      '';

      symlinks = ''
        if [ "$(uname -s)" == "Darwin" ]; then
            if ! [ -d $HOME/Downloads ] && ! [ -L $HOME/Downloads ]; then
                echo "Moving ~/Downloads to symlink into iCloud."

                /usr/bin/sudo rm -rf $HOME/Downloads
                ln -sf $HOME/iCloud/Downloads $HOME/Downloads
            fi

            if ! [ -L $HOME/iCloud ]; then
                ln -s $HOME/Library/Mobile\ Documents/com~apple~CloudDocs $HOME/iCloud
            fi
        fi

        if ! [ -L $HOME/src ]; then
            ln -sf $HOME/dev/src $HOME/src
        fi
      '';
    };

    defaultShell = pkgs.fish;
  };

  programs = {
    # https://github.com/me-and/nixcfg/blob/689c91c8f5bdd7bed0d95ba2c85f6466d8b7452f/nixos/common/nix-index.nix#L11
    command-not-found.enable = false;

    direnv = {
      nix-direnv.enable = true;
    };

    home-manager.enable = true;

    nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 4d --keep 3";
      flake = "${config.xdg.configHome}/nix";
    };

    # generate index with: nix-index --filter-prefix '/bin/'
    nix-index = {
      enable = true;
      enableBashIntegration = false;
      enableZshIntegration = false;
      enableFishIntegration = true;
    };
  };

  targets.darwin.linkApps.enable = false;
}
