{lib, ...}: {
  # `programs.git` will generate the config file: ~/.config/git/config
  # to make git use this config file, `~/.gitconfig` should not exist!
  #
  #    https://git-scm.com/docs/git-config#Documentation/git-config.txt---global
  home.activation.removeExistingGitconfig = lib.hm.dag.entryBefore ["checkLinkTargets"] ''
    rm -f ~/.gitconfig
  '';

  programs.git = {
    enable = true;
    lfs.enable = true;

    includes = [
      {path = "conf.d/alias.conf";}
      {path = "conf.d/delta.conf";}
      {path = "conf.d/lfs.conf";}
      {path = "conf.d/gist.conf";}
      {path = "conf.d/ghq.conf";}
      {
        condition = "hasconfig:remote.*.url:git@github.com:dsully/**";
        path = "~/.config/git/conf.d/public.conf";
      }
    ];

    userEmail = lib.mkDefault "dsully@users.noreply.github.com";

    extraConfig = {
      advice.skippedCherryPicks = false;

      branch = {
        autoSetupMerge = true;
        autoSetupRebase = "always";
      };

      color = {
        branch = "auto";
        interactive = "auto";
        status = "auto";
        ui = true;
      };

      column.ui = "auto";

      core = {
        sshCommand = "/usr/bin/ssh";

        # Make `git rebase` safer on macOS.
        # More info: <http://www.git-tower.com/blog/make-git-rebase-safe-on-osx/>
        trustctime = false;

        # Speed up commands involving untracked files such as `git status`.
        # https://git-scm.com/docs/git-update-index#_untracked_cache
        untrackedCache = true;
      };

      diff = {
        navigate = true; # use n and N to move between diff sections
        renames = "copies"; # Detect copies as well as renames.

        algorithm = "histogram"; # Better diffing algorithm.
        colorMoved = "zebra"; # Highlight moved lines as oldMoved -> newMoved.
        mnemonicPrefix = true; # Use better letters than a/ and b/ in diffs.
      };

      dive.theme = "Nord";

      fetch = {
        # Delete local tracking branches if remote is gone.
        # https://stackoverflow.com/questions/60458452/how-can-i-list-all-remote-existing-branches-in-git
        prune = true;
        fsckObjects = true;
        # Cache commit graph to speed up graph log / push operations on fetch.
        writeCommitGraph = true;
      };

      filter = {
        gitignore = {
          clean = "sed '/#gitignore$/d'";
          smudge = "cat";
        };
      };

      # Automatically correct and execute mistyped commands.
      help.autocorrect = "immediate";

      init.defaultBranch = "main";

      mergetool = {
        cmd = "nvim";
        hideResolved = true; # Don't show merge conflicts that have already been resolved by git in the mergetool diff.
        prompt = false; # Don't confirm that I want to open the difftool every time.
      };

      pull.rebase = true;

      push = {
        default = "upstream";
        autoSetupRemote = true;
      };

      rebase = {
        autoSquash = true;
        autoStash = true;
        stat = true;
      };

      rerere = {
        enabled = true;
        autoUpdate = true;
      };

      status = {
        relativePaths = true;
        submoduleSummary = true;
      };

      url = {
        "git@github.com:" = {
          insteadOf = "gh:";
          pushInsteadOf = "git://github.com/";
        };
        "git://github.com/" = {
          insteadOf = "github:";
        };
      };

      user = {
        name = "Dan Sully";
        useConfigOnly = true;
      };
    };
  };
}
