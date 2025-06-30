{
  flake,
  lib,
  pkgs,
  ...
}: let
  editor = lib.getExe pkgs.neovim;
  username = (flake.inputs.upstream or flake).lib.defaultUser;
in {
  # `programs.git` will generate the config file: ~/.config/git/config
  # to make git use this config file, `~/.gitconfig` should not exist!
  #
  #    https://git-scm.com/docs/git-config#Documentation/git-config.txt---global
  home = {
    activation = {
      removeExistingGitconfig = lib.hm.dag.entryBefore ["checkLinkTargets"] "/bin/rm -f ~/.gitconfig";
    };

    file = {
      ".config/git/public.conf" = {
        force = true;
        text = lib.generators.toGitINI {
          user.email = flake.lib.publicEmail;
        };
      };
    };
  };

  programs.git = {
    enable = true;
    lfs.enable = true;

    aliases = {
      # Basic shortcuts
      a = "commit --amend";
      aa = "add --all";
      amend = "commit --amend";
      co = "checkout";
      dc = "diff --cached";
      st = "status -sb";
      unadd = "restore --staged";
      unstage = "reset HEAD --";
      untrack = "rm --cached";

      # Diff operations
      dlc = "diff --cached HEAD^";

      # Information commands
      aliases = "config --get-regexp alias";
      first = "rev-list --max-parents=0 HEAD";
      incoming = "log HEAD..@{upstream}";
      last = "log -1 HEAD";
      mine = "log --author=${username}";
      outgoing = "log @{upstream}..HEAD";
      root = "rev-parse --show-toplevel";
      whoami = "config user.email";

      # Push/pull operations
      fpush = "push --force-with-lease";

      # GitHub integration
      actions = "!f() { gh run list --branch $(git rev-parse --abbrev-ref HEAD); }; f";
      browse = "!gh repo view --web";
      pr = "!f() { git fetch -fu \${2:-origin} refs/pull/$1/head:pr/$1 && git checkout pr/$1; }; f";
      prs = "!hub pr list --format='%pC%i%Creset %au: %t %l %n ▸ %U%n%n' -o updated";

      # Branch operations
      br = "!f() { git checkout -b \"$1\" 2> /dev/null || git checkout \"$1\"; }; f";
      recent = "for-each-ref --count=20 --sort=-committerdate refs/heads/ --format=\"%(refname:short)\"";

      # Log formatting
      l = "log --pretty=oneline -n 20 --graph --abbrev-commit";
      lp = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --decorate --date=short --color --decorate";
      lg = "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --";
      overview = "log --all --since='2 weeks' --oneline --no-merges";
      recap = "!git log --all --oneline --no-merges --author=$(git config user.email)";
      today = "!git log --since=00:00:00 --all --oneline --no-merges --author=$(git config user.email)";

      # Search and find
      find = "log -G";
      filter-commits = "!sh -c 'git log --pretty=format:\"%h - %an: %s\" $1 | fzf --no-sort | cut -d \" \" -f1 ' -";

      # Editor integration
      mc = "!git diff --name-only --diff-filter=U | tr '\\n' '\\0' | xargs -0 $EDITOR -c '/^\\(|||||||\\|=======\\|>>>>>>>\\|<<<<<<<\\)'";
      review = "!nvim -c \"DiffviewFileHistory --range=origin/HEAD...HEAD --right-only --no-merges\"";

      # fzf
      brc = "!export MASTER_BRANCH=$(git branch -r | grep -Po 'HEAD -> \\K.*$') && git diff --name-only $MASTER_BRANCH | fzf --ansi --preview 'git diff --color=always $MASTER_BRANCH {}' --bind 'enter:become($EDITOR {})'";
      # Find-Add
      fa = "!git ls-files -m -o --exclude-standard | fzf --print0 -m | xargs -0 -t -o git add";

      # Utility commands
      rescue = "!git fsck --full --no-reflogs --unreachable --lost-found | grep commit | cut -d\\  -f3 | xargs -n 1 git log -n 1 --pretty=oneline > .git/lost-found.txt";
      pending = "!git log $(git describe --tags --abbrev=0)..HEAD --oneline";
      fixup = "!git commit --fixup $(git rev-parse HEAD)";
    };

    delta = {
      enable = true;

      options = {
        # Basic options
        hyperlinks = true;
        keep-plus-minus-markers = false;
        line-numbers = false;
        navigate = true;
        relative-paths = true;
        side-by-side = false;
        true-color = "always";

        # Color definitions
        bg-green = "#8aa872";
        bg-red = "#a54e56";

        # Blame settings
        blame-code-style = "syntax";
        blame-format = "{author:<18} {commit:<6} {timestamp:<15}";
        blame-palette = "#2E3440 #3B4252 #434C5E";

        # File labels
        file-added-label = "[+]";
        file-copied-label = "[==]";
        file-modified-label = "[*]";
        file-removed-label = "[-]";
        file-renamed-label = "[->]";
        file-style = "omit";
        file-transformation = "s,(.*),  $1,";

        # Hunk header settings
        hunk-header-decoration-style = "blue ul";
        hunk-header-file-style = "blue bold";
        hunk-header-line-number-style = "white bold";
        hunk-header-style = "file line-number syntax bold italic";
        hunk-label = "";

        # Diff styling
        minus-emph-style = "white bg-red";
        minus-non-emph-style = "syntax normal";
        minus-style = "white bg-red";
        plus-emph-style = "black bg-green";
        plus-non-emph-style = "syntax normal";
        plus-style = "black bg-green";

        # Theme and display
        syntax-theme = "Nord";
        width = "variable";
        whitespace-error-style = "black bold";
        zero-style = "syntax";
      };
    };

    ignores = [
      # Python
      "__pypackages__/"
      "*.pyc"
      "*.pyo"
      "*.egg"
      "*.egg-info/"
      ".mypy_cache"
      ".pytest_cache/"
      ".ruff_cache"
      "dist/"
      "mypy_cache/"

      # AI
      ".aider*"
      "*.ckpt"
      "*.safetensors"
      "**/.claude/settings.local.json"

      # Build artifacts
      ".cache/"
      ".ccls-cache"
      "build/"
      "htmlcov/"
      "target/"

      # Node.js
      ".node_repl_history"

      # Environment
      ".direnv/"

      # IDE
      "*.iml"
      "*.ipr"
      "*.iws"
      "*.swo"
      "*.swp"
      "*.vscode"

      # OS specific
      ".DS_Store"
      "Icon?"
      "Thumbs.db"

      # Language servers
      "/.pkl-lsp/"
    ];

    includes = [
      {
        condition = "hasconfig:remote.*.url:https://github.com/**";
        path = "public.conf";
      }
      {
        condition = "hasconfig:remote.*.url:git@github.com:*/**";
        path = "public.conf";
      }
    ];

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
        # https://stackoverflow.com/questions/4994772/ways-to-improve-git-status-performance
        fsmonitor = false;

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

        lfs = {
          smudge = "git-lfs smudge -- %f";
          process = "git-lfs filter-process";
          required = true;
          clean = "git-lfs clean -- %f";
        };
      };

      # Automatically correct and execute mistyped commands.
      help.autocorrect = "immediate";

      init.defaultBranch = "main";

      mergetool = {
        cmd = editor;
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
        showUntrackedFiles = true;
        submoduleSummary = false;
      };

      trim = {
        bases = "main,master,develop";
        confirm = false;
        update = true;
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
        name = username;
        useConfigOnly = true;
      };
    };
  };
}
