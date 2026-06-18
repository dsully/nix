let
  pythonVersion = "3.14";
in {
  programs.uv = {
    enable = true;

    python = {
      versions = [pythonVersion];
      default = pythonVersion;
    };

    # uv tool install takes no per-tool --python, so pin the interpreter
    # globally: install/default 3.14 and refuse non-managed pythons.
    settings = {
      preview = true;
      python-preference = "only-managed";
    };
  };

  xdg.configFile."ptpython/config.py".text = builtins.readFile ../../../dotfiles/ptpython/config.py;
}
