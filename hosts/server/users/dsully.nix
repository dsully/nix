{
  flake,
  pkgs,
  ...
}: {
  _module.args.username = "dsully";

  imports = [
    flake.homeModules.dsully
  ];

  home = {
    packages = with pkgs; [
      autorebase
      bacon
      claude-code
      ghostscript_headless
      git-ai-commit
      nix-output-monitor
      pandoc
      systemd-language-server
      turbo-commit
    ];
  };
}
