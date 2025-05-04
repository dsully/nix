{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    morlana
    sps
  ];
}
