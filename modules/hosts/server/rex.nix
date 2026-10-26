{
  inputs,
  lib,
  ...
}:
lib.optionalAttrs (inputs ? rex) {
  imports = [inputs.rex.homeManagerModules.default];

  services.rex = {
    enable = true;
    tailscale.enable = true;
  };
}
