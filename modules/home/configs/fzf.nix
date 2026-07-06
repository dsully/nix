{
  config,
  lib,
  ...
}: let
  c = config.colors;
  inherit (config.programs) fd;
  fdOptions = lib.concatStringsSep " " (
    ["--color always"]
    ++ lib.optional fd.hidden "--hidden"
    ++ fd.extraOptions
  );
in {
  programs.fzf = {
    enable = true;
    enableFishIntegration = true;

    defaultCommand = "fd --type f --type l ${fdOptions}";
    fileWidget.command = "fd --type f ${fdOptions}";
    changeDirWidget.command = "fd --type d ${fdOptions}";

    defaultOptions = [
      "--ansi"
      "--cycle"
      "--filepath-word"
      "--height=50%"
      "--info=hidden"
      "--layout=reverse-list"
      "--border=sharp"
    ];

    colors = {
      "bg+" = c.black.base;
      bg = c.black.dim;
      spinner = c.blue.base;
      hl = c.extra.fzfHl;
      fg = c.white.dim;
      header = c.extra.fzfHl;
      border = c.gray.base;
      info = c.blue.base;
      pointer = c.red.base;
      marker = c.red.base;
      "fg+" = c.blue.base;
      prompt = c.blue.base;
      "hl+" = c.blue.base;
    };
  };
}
