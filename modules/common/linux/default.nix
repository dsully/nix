{
  flake,
  pkgs,
  ...
}: {
  environment = {
    pathsToLink = ["/share/fish"];

    systemPackages = with pkgs; [
      flake.inputs.system-manager.packages.${system}.default
    ];
  };
}
