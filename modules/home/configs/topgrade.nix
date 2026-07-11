{pkgs, ...}: {
  programs.topgrade = {
    enable = true;

    # cctools ld (1010.6) segfaults linking the AppKit/Foundation frameworks
    # pulled in via mac-notification-sys; force the LLVM linker on Darwin.
    package =
      if pkgs.stdenv.isDarwin
      then
        pkgs.topgrade.overrideAttrs (old: {
          nativeBuildInputs = (old.nativeBuildInputs or []) ++ [pkgs.lld];
          RUSTFLAGS = "-C link-arg=-fuse-ld=lld";
        })
      else pkgs.topgrade;

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
