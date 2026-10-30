{mkUserModule, ...}:
mkUserModule {
  name = "core-shell";
  default = false;

  requires = [
    "btop"
    "delta"
    "direnv"
    "dotfiles"
    "editor"
    "fd"
    "fish"
    "fzf"
    "git"
    "home-base"
    "lla"
    "pager"
    "procs"
    "ripgrep"
    "system-tools"
    "vivid"
    "zoxide"
  ];
}
