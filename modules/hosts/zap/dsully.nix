{pkgs, ...}: {
  home = {
    packages = with pkgs; [
      nix-output-monitor
    ];
  };

  services = {
    syncthing = {
      enable = true;
      extraOptions = ["--log-level=WARN"];
    };
  };
}
