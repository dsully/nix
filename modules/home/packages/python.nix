{
  lib,
  pkgs,
  ...
}: let
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

  # Home Manager's activation PATH omits /usr/bin, so `uv python install`
  # (run by programs.uv during activation) can't find Apple's
  # install_name_tool to patch and re-sign the freshly installed Python dylib
  # on macOS. Without it uv warns "Failed to patch the install name of the
  # dynamic library" and leaves the dylib unusable for building native
  # extensions. Prepend /usr/bin before the uv activation runs so it finds
  # Apple's tool. The activation script is a single shell process, so this
  # export carries into the uvPython block ordered after it.
  home.activation.uvInstallNameToolPath = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin (
    lib.hm.dag.entryBefore ["uvPython"] ''
      export PATH="/usr/bin:$PATH"
    ''
  );

  xdg.configFile."ptpython/config.py".text = builtins.readFile ../../../dotfiles/ptpython/config.py;
}
