{mkUser, ...}:
mkUser {
  name = "dsully";
  stateVersion = "25.05";

  home-base.enable = true;
  chsh.enable = true;
  dotfiles.enable = true;

  btop.enable = true;
  direnv.enable = true;
  fd.enable = true;
  fish.enable = true;
  fselect.enable = true;
  fzf.enable = true;
  lla.enable = true;
  local-tools.enable = true;
  lolcate.enable = true;
  pager.enable = true;
  procs.enable = true;
  ripgrep.enable = true;
  ssh.enable = true;
  system-tools.enable = true;
  syswatch.enable = true;
  topgrade.enable = true;
  vivid.enable = true;
  zoxide.enable = true;

  delta.enable = true;
  dev-tools.enable = true;
  editorconfig.enable = true;
  emmylua.enable = true;
  gh.enable = true;
  git.enable = true;
  gitui.enable = true;
  javascript.enable = true;
  nix-init.enable = true;
  nix-tools.enable = true;
  python.enable = true;
  ruff.enable = true;
  rust.enable = true;
  tombi.enable = true;
  yamllint.enable = true;

  editor.enable = true;
  ghostty.enable = true;

  ai.enable = true;
  ccstatusline.enable = true;
  claude-code.enable = true;
  herdr.enable = true;
  mcp-mux.enable = true;
  opencode.enable = true;
  skills.enable = true;
}
