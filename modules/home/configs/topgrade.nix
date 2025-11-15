{
  programs.topgrade = {
    enable = true;

    settings = {
      misc = {
        assume_yes = true;
        cleanup = true;
        ignore_failures = ["git_repos"];
        no_retry = true;
        run_in_tmux = false;
        skip_notify = true;
      };

      git = {
        arguments = "--rebase --autostash";
        pull_predefined = false;
      };

      commands = {};
      pre_commands = {};

      brew = {
        greedy_cask = true;
      };

      npm = {
        use_sudo = true;
      };

      firmware = {
        upgrade = false;
      };

      flatpak = {
        use_sudo = true;
      };
    };
  };
}
