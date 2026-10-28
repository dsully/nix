{
  inputs,
  lib,
  ...
}:
lib.optionalAttrs (inputs ? rex) {
  imports = [inputs.rex.homeManagerModules.default];

  services.rex = {
    enable = true;
    extraListen = ["tailnet://:7297"];
  };
}
