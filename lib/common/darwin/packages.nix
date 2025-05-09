{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    sps
  ];
}
